#!/usr/bin/env python3
"""Fetch Grok Build account credit usage (same source as /usage).

Reads OIDC tokens from ~/.grok/auth.json, silently refreshes via
https://auth.x.ai/oauth2/token when the access token is expired or near
expiry, then calls:
  GET https://cli-chat-proxy.grok.com/v1/billing?format=credits

Prints one JSON object on stdout for Quickshell Process consumption.
Caches last good payload under ~/.cache/quickshell/warmind/grok-usage.json
so a failed refresh can still paint the panel (marked stale).
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

AUTH_PATH = Path.home() / ".grok" / "auth.json"
CACHE_PATH = (
    Path.home() / ".cache" / "quickshell" / "warmind" / "grok-usage.json"
)
BILLING_URL = "https://cli-chat-proxy.grok.com/v1/billing?format=credits"
DEFAULT_TOKEN_URL = "https://auth.x.ai/oauth2/token"
TIMEOUT_S = 12
# Refresh this many seconds before expires_at (matches Grok CLI early skew spirit).
REFRESH_SKEW_S = 120

ERR_AUTH_MISSING = "failed to pull auth token"
ERR_AUTH_REFRESH = "could not refresh auth token"
ERR_AUTH_STALE = "stale auth token"
ERR_BILLING_PARSE = "failed to parse billing response"


class AuthError(Exception):
    """User-facing auth failure with a stable error string."""

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def utc_now_iso() -> str:
    return utc_now().replace(microsecond=0).isoformat()


def empty_result(error: str = "", stale: bool = False) -> dict[str, Any]:
    return {
        "ready": False,
        "stale": stale,
        "error": error,
        "percent": None,
        "periodType": "",
        "periodStart": "",
        "periodEnd": "",
        "products": [],
        "prepaidBalance": 0,
        "onDemandUsed": 0,
        "onDemandCap": 0,
        "isUnifiedBillingUser": False,
        "fetchedAt": "",
    }


def unwrap_val(value: Any) -> Any:
    if isinstance(value, dict) and "val" in value:
        return value.get("val")
    return value


def parse_expires_at(raw: Any) -> datetime | None:
    if raw is None:
        return None
    text = str(raw).strip()
    if not text:
        return None
    # Support trailing Z and optional fractional seconds.
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(text)
    except ValueError:
        # Truncate over-precise fractions if needed.
        if "." in text:
            head, rest = text.split(".", 1)
            frac = ""
            tz = ""
            for i, ch in enumerate(rest):
                if ch.isdigit():
                    frac += ch
                else:
                    tz = rest[i:]
                    break
            frac = (frac + "000000")[:6]
            try:
                dt = datetime.fromisoformat(f"{head}.{frac}{tz}")
            except ValueError:
                return None
        else:
            return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def jwt_exp(token: str) -> datetime | None:
    try:
        parts = token.split(".")
        if len(parts) < 2:
            return None
        import base64

        pad = "=" * (-len(parts[1]) % 4)
        payload = json.loads(base64.urlsafe_b64decode(parts[1] + pad))
        exp = payload.get("exp")
        if exp is None:
            return None
        return datetime.fromtimestamp(int(exp), tz=timezone.utc)
    except Exception:
        return None


def load_auth() -> tuple[dict[str, Any], str, dict[str, Any]]:
    """Return (full_doc, entry_key, entry). Raises AuthError."""
    if not AUTH_PATH.is_file():
        raise AuthError(ERR_AUTH_MISSING)
    try:
        data = json.loads(AUTH_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        raise AuthError(ERR_AUTH_MISSING) from exc
    if not isinstance(data, dict) or not data:
        raise AuthError(ERR_AUTH_MISSING)
    entry_key = next(iter(data.keys()))
    entry = data[entry_key]
    if not isinstance(entry, dict):
        raise AuthError(ERR_AUTH_MISSING)
    token = str(entry.get("key") or entry.get("access_token") or "")
    refresh = str(entry.get("refresh_token") or "")
    if not token and not refresh:
        raise AuthError(ERR_AUTH_MISSING)
    return data, str(entry_key), entry


def access_token(entry: dict[str, Any]) -> str:
    return str(entry.get("key") or entry.get("access_token") or "")


def token_needs_refresh(entry: dict[str, Any]) -> bool:
    token = access_token(entry)
    if not token:
        return True
    exp = parse_expires_at(entry.get("expires_at")) or jwt_exp(token)
    if exp is None:
        # Unknown expiry: try once; billing 401 will force refresh.
        return False
    return utc_now() >= (exp - timedelta(seconds=REFRESH_SKEW_S))


def token_url_for(entry: dict[str, Any]) -> str:
    issuer = str(entry.get("oidc_issuer") or "https://auth.x.ai").rstrip("/")
    if issuer == "https://auth.x.ai":
        return DEFAULT_TOKEN_URL
    # Best-effort discovery; fall back to default path.
    try:
        disc_url = f"{issuer}/.well-known/openid-configuration"
        req = urllib.request.Request(
            disc_url,
            headers={"Accept": "application/json", "User-Agent": "warmind-grok-usage/1.1"},
            method="GET",
        )
        with urllib.request.urlopen(req, timeout=TIMEOUT_S) as resp:
            doc = json.loads(resp.read().decode("utf-8"))
        endpoint = doc.get("token_endpoint")
        if endpoint:
            return str(endpoint)
    except Exception:
        pass
    return f"{issuer}/oauth2/token"


def persist_auth(doc: dict[str, Any]) -> None:
    AUTH_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(doc, indent=2) + "\n"
    fd, tmp_name = tempfile.mkstemp(
        prefix="auth.", suffix=".json", dir=str(AUTH_PATH.parent)
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(payload)
            fh.flush()
            os.fsync(fh.fileno())
        os.chmod(tmp_name, 0o600)
        os.replace(tmp_name, AUTH_PATH)
    except Exception:
        try:
            os.unlink(tmp_name)
        except OSError:
            pass
        raise


def refresh_access_token(
    doc: dict[str, Any], entry_key: str, entry: dict[str, Any]
) -> str:
    refresh = str(entry.get("refresh_token") or "")
    client_id = str(entry.get("oidc_client_id") or "")
    if not refresh or not client_id:
        raise AuthError(ERR_AUTH_REFRESH)

    body = urllib.parse.urlencode(
        {
            "grant_type": "refresh_token",
            "refresh_token": refresh,
            "client_id": client_id,
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        token_url_for(entry),
        data=body,
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json",
            "User-Agent": "warmind-grok-usage/1.1",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT_S) as resp:
            raw = resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        raise AuthError(ERR_AUTH_REFRESH) from exc
    except Exception as exc:
        raise AuthError(ERR_AUTH_REFRESH) from exc

    try:
        payload = json.loads(raw)
    except Exception as exc:
        raise AuthError(ERR_AUTH_REFRESH) from exc
    if not isinstance(payload, dict):
        raise AuthError(ERR_AUTH_REFRESH)

    new_access = str(payload.get("access_token") or "")
    if not new_access:
        raise AuthError(ERR_AUTH_REFRESH)

    entry["key"] = new_access
    new_refresh = payload.get("refresh_token")
    if new_refresh:
        entry["refresh_token"] = str(new_refresh)

    expires_in = payload.get("expires_in")
    try:
        seconds = int(expires_in) if expires_in is not None else 0
    except (TypeError, ValueError):
        seconds = 0
    if seconds <= 0:
        exp = jwt_exp(new_access)
        if exp is not None:
            entry["expires_at"] = exp.isoformat().replace("+00:00", "Z")
        else:
            entry["expires_at"] = (utc_now() + timedelta(hours=6)).isoformat().replace(
                "+00:00", "Z"
            )
    else:
        entry["expires_at"] = (
            utc_now() + timedelta(seconds=seconds)
        ).isoformat().replace("+00:00", "Z")

    doc[entry_key] = entry
    try:
        persist_auth(doc)
    except Exception:
        # Still return the fresh token even if disk write fails.
        pass
    return new_access


def ensure_access_token() -> str:
    doc, entry_key, entry = load_auth()
    token = access_token(entry)
    if token_needs_refresh(entry):
        token = refresh_access_token(doc, entry_key, entry)
    if not token:
        raise AuthError(ERR_AUTH_MISSING)
    return token


def fetch_billing(token: str) -> dict[str, Any]:
    req = urllib.request.Request(
        BILLING_URL,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
            "User-Agent": "warmind-grok-usage/1.1",
        },
        method="GET",
    )
    with urllib.request.urlopen(req, timeout=TIMEOUT_S) as resp:
        body = resp.read().decode("utf-8")
    try:
        payload = json.loads(body)
    except Exception as exc:
        raise ValueError(ERR_BILLING_PARSE) from exc
    if not isinstance(payload, dict):
        raise ValueError(ERR_BILLING_PARSE)
    return payload


def fetch_billing_with_auth() -> dict[str, Any]:
    token = ensure_access_token()
    try:
        return fetch_billing(token)
    except urllib.error.HTTPError as exc:
        if exc.code != 401:
            raise
        # Force one refresh and retry.
        doc, entry_key, entry = load_auth()
        token = refresh_access_token(doc, entry_key, entry)
        try:
            return fetch_billing(token)
        except urllib.error.HTTPError as retry_exc:
            if retry_exc.code == 401:
                raise AuthError(ERR_AUTH_STALE) from retry_exc
            raise


def normalize(payload: dict[str, Any]) -> dict[str, Any]:
    cfg = payload.get("config") if isinstance(payload.get("config"), dict) else payload
    period = cfg.get("currentPeriod") if isinstance(cfg.get("currentPeriod"), dict) else {}

    products_raw = cfg.get("productUsage") or []
    products: list[dict[str, Any]] = []
    if isinstance(products_raw, list):
        for item in products_raw:
            if not isinstance(item, dict):
                continue
            products.append(
                {
                    "product": str(item.get("product") or "Unknown"),
                    "usagePercent": float(item.get("usagePercent") or 0),
                }
            )
    products.sort(key=lambda p: p["usagePercent"], reverse=True)

    percent = cfg.get("creditUsagePercent")
    try:
        percent_f = float(percent) if percent is not None else None
    except (TypeError, ValueError):
        percent_f = None

    return {
        "ready": True,
        "stale": False,
        "error": "",
        "percent": percent_f,
        "periodType": str(period.get("type") or ""),
        "periodStart": str(period.get("start") or cfg.get("billingPeriodStart") or ""),
        "periodEnd": str(period.get("end") or cfg.get("billingPeriodEnd") or ""),
        "products": products,
        "prepaidBalance": float(unwrap_val(cfg.get("prepaidBalance")) or 0),
        "onDemandUsed": float(unwrap_val(cfg.get("onDemandUsed")) or 0),
        "onDemandCap": float(unwrap_val(cfg.get("onDemandCap")) or 0),
        "isUnifiedBillingUser": bool(cfg.get("isUnifiedBillingUser")),
        "fetchedAt": utc_now_iso(),
    }


def read_cache() -> dict[str, Any] | None:
    if not CACHE_PATH.is_file():
        return None
    try:
        data = json.loads(CACHE_PATH.read_text(encoding="utf-8"))
    except Exception:
        return None
    if not isinstance(data, dict) or not data.get("ready"):
        return None
    return data


def write_cache(data: dict[str, Any]) -> None:
    try:
        CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
        CACHE_PATH.write_text(json.dumps(data), encoding="utf-8")
    except Exception:
        pass


def emit(data: dict[str, Any], exit_code: int = 0) -> None:
    sys.stdout.write(json.dumps(data, separators=(",", ":")))
    sys.stdout.write("\n")
    sys.stdout.flush()
    raise SystemExit(exit_code)


def emit_failure(error: str) -> None:
    cached = read_cache()
    if cached:
        cached = dict(cached)
        cached["stale"] = True
        # Keep the specific auth message so the user knows why data is stale.
        cached["error"] = error
        emit(cached, 0)
    emit(empty_result(error=error), 1)


def main() -> None:
    try:
        payload = fetch_billing_with_auth()
        result = normalize(payload)
        write_cache(result)
        emit(result, 0)
    except AuthError as exc:
        emit_failure(exc.message)
    except urllib.error.HTTPError as exc:
        emit_failure(f"billing request failed (HTTP {exc.code})")
    except ValueError as exc:
        msg = str(exc) or ERR_BILLING_PARSE
        emit_failure(msg if msg == ERR_BILLING_PARSE else msg)
    except Exception as exc:
        emit_failure(str(exc) or type(exc).__name__)


if __name__ == "__main__":
    main()
