#!/usr/bin/env python3
"""Fetch Codex account usage via app-server JSON-RPC.

Uses the same backend as interactive `/usage daily|weekly`:
  codex -s read-only -a untrusted app-server
    account/read
    account/rateLimits/read
    account/usage/read

Prints one JSON object on stdout for Quickshell. Caches last good payload
under ~/.cache/quickshell/warmind/codex-usage.json.
"""

from __future__ import annotations

import json
import os
import select
import shutil
import subprocess
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

AUTH_PATH = Path.home() / ".codex" / "auth.json"
CACHE_PATH = (
    Path.home() / ".cache" / "quickshell" / "warmind" / "codex-usage.json"
)
TIMEOUT_S = 12

ERR_AUTH_MISSING = "failed to pull auth token"
ERR_CODEX_UNAVAILABLE = "codex unavailable"
ERR_RPC_FAILED = "could not read codex usage"
ERR_AUTH_STALE = "stale auth token"


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def empty_result(error: str = "", stale: bool = False) -> dict[str, Any]:
    return {
        "ready": False,
        "stale": stale,
        "error": error,
        "email": "",
        "planType": "",
        "primaryPercent": None,
        "primaryLabel": "",
        "primaryResetsAt": "",
        "secondaryPercent": None,
        "secondaryLabel": "",
        "secondaryResetsAt": "",
        "creditsBalance": 0,
        "creditsUnlimited": False,
        "hasCredits": False,
        "todayTokens": 0,
        "recentDays": [],
        "lifetimeTokens": 0,
        "peakDailyTokens": 0,
        "currentStreakDays": 0,
        "longestStreakDays": 0,
        "fetchedAt": "",
    }


def runtime_env() -> dict[str, str]:
    home = str(Path.home())
    path_parts = [
        os.environ.get("PATH", ""),
        f"{home}/.local/bin",
        f"{home}/.local/npm-global/bin",
        f"{home}/.npm-global/bin",
        f"{home}/.local/share/mise/shims",
    ]
    env = os.environ.copy()
    env["PATH"] = os.pathsep.join(p for p in path_parts if p)
    return env


def find_codex() -> str | None:
    return shutil.which("codex", path=runtime_env().get("PATH"))


def require_auth() -> None:
    if not AUTH_PATH.is_file():
        raise RuntimeError(ERR_AUTH_MISSING)
    try:
        data = json.loads(AUTH_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        raise RuntimeError(ERR_AUTH_MISSING) from exc
    if not isinstance(data, dict):
        raise RuntimeError(ERR_AUTH_MISSING)
    tokens = data.get("tokens") if isinstance(data.get("tokens"), dict) else {}
    has_access = bool(tokens.get("access_token") or data.get("OPENAI_API_KEY"))
    if not has_access and data.get("auth_mode") not in ("chatgpt", "api_key", "apikey"):
        # Still allow if auth_mode present; Codex may refresh itself.
        if not data.get("auth_mode"):
            raise RuntimeError(ERR_AUTH_MISSING)


def window_label(mins: int) -> str:
    if mins <= 0:
        return "Window"
    if mins == 10080:
        return "Weekly (7-day)"
    if mins == 1440:
        return "Daily (24h)"
    if mins % (60 * 24) == 0:
        days = mins // (60 * 24)
        return f"{days}-day window"
    if mins % 60 == 0:
        return f"{mins // 60}h window"
    return f"{mins}m window"


def as_percent(value: Any) -> float | None:
    if value is None:
        return None
    try:
        n = float(value)
    except (TypeError, ValueError):
        return None
    # API may return 0-100 or 0-1 fraction.
    if 0 < n <= 1:
        n *= 100.0
    return max(0.0, min(100.0, n))


def resets_iso(epoch: Any) -> str:
    try:
        ts = int(epoch or 0)
    except (TypeError, ValueError):
        return ""
    if ts <= 0:
        return ""
    return datetime.fromtimestamp(ts, timezone.utc).replace(microsecond=0).isoformat()


def fill_window(window: Any) -> tuple[float | None, str, str]:
    if not isinstance(window, dict):
        return None, "", ""
    pct = as_percent(window.get("usedPercent"))
    mins = 0
    try:
        mins = int(window.get("windowDurationMins") or 0)
    except (TypeError, ValueError):
        mins = 0
    label = window_label(mins) if mins else "Limit"
    reset = resets_iso(window.get("resetsAt"))
    return pct, label, reset


class CodexRpc:
    def __init__(self, codex_bin: str) -> None:
        self.proc = subprocess.Popen(
            [codex_bin, "-s", "read-only", "-a", "untrusted", "app-server"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            env=runtime_env(),
        )
        self._id = 0

    def close(self) -> None:
        if self.proc.poll() is not None:
            return
        try:
            self.proc.terminate()
            self.proc.wait(timeout=1.5)
        except Exception:
            try:
                self.proc.kill()
            except Exception:
                pass

    def request(self, method: str, params: dict[str, Any] | None = None, timeout: float = 8.0) -> dict[str, Any]:
        if not self.proc.stdin or not self.proc.stdout:
            raise RuntimeError(ERR_RPC_FAILED)
        self._id += 1
        req_id = self._id
        msg: dict[str, Any] = {"id": req_id, "method": method}
        if params is not None:
            msg["params"] = params
        self.proc.stdin.write(json.dumps(msg) + "\n")
        self.proc.stdin.flush()
        deadline = time.time() + timeout
        while time.time() < deadline:
            ready, _, _ = select.select([self.proc.stdout], [], [], 0.25)
            if not ready:
                continue
            line = self.proc.stdout.readline()
            if not line:
                break
            try:
                payload = json.loads(line)
            except Exception:
                continue
            if payload.get("id") == req_id:
                if "error" in payload:
                    err = payload.get("error") or {}
                    text = str(err.get("message") or err or ERR_RPC_FAILED)
                    low = text.lower()
                    if "auth" in low or "unauthorized" in low or "login" in low:
                        raise RuntimeError(ERR_AUTH_STALE)
                    raise RuntimeError(ERR_RPC_FAILED)
                result = payload.get("result")
                return result if isinstance(result, dict) else {}
        raise RuntimeError(ERR_RPC_FAILED)

    def notify(self, method: str, params: dict[str, Any] | None = None) -> None:
        if not self.proc.stdin:
            return
        msg: dict[str, Any] = {"method": method}
        if params is not None:
            msg["params"] = params
        self.proc.stdin.write(json.dumps(msg) + "\n")
        self.proc.stdin.flush()


def recent_days_from_buckets(buckets: list[Any]) -> tuple[list[dict[str, Any]], int]:
    today = datetime.now().date()
    by_day: dict[str, int] = {}
    for item in buckets:
        if not isinstance(item, dict):
            continue
        day = str(item.get("startDate") or "")
        if not day:
            continue
        try:
            tokens = int(item.get("tokens") or 0)
        except (TypeError, ValueError):
            tokens = 0
        by_day[day] = by_day.get(day, 0) + max(0, tokens)

    out: list[dict[str, Any]] = []
    today_tokens = 0
    for offset in range(6, -1, -1):
        d = (today - timedelta(days=offset)).strftime("%Y-%m-%d")
        toks = int(by_day.get(d, 0))
        out.append({"date": d, "tokens": toks})
        if offset == 0:
            today_tokens = toks
    return out, today_tokens


def fetch_usage() -> dict[str, Any]:
    require_auth()
    codex = find_codex()
    if not codex:
        raise RuntimeError(ERR_CODEX_UNAVAILABLE)

    rpc = CodexRpc(codex)
    try:
        rpc.request(
            "initialize",
            {"clientInfo": {"name": "warmind-codex-usage", "version": "1"}},
            timeout=8,
        )
        rpc.notify("initialized", {})
        account_msg = rpc.request("account/read", {}, timeout=6)
        limits_msg = rpc.request("account/rateLimits/read", {}, timeout=6)
        usage_msg = rpc.request("account/usage/read", {}, timeout=8)
    finally:
        rpc.close()

    account = account_msg.get("account") if isinstance(account_msg.get("account"), dict) else {}
    limits = limits_msg.get("rateLimits") if isinstance(limits_msg.get("rateLimits"), dict) else {}
    credits = limits.get("credits") if isinstance(limits.get("credits"), dict) else {}
    summary = usage_msg.get("summary") if isinstance(usage_msg.get("summary"), dict) else {}
    buckets = usage_msg.get("dailyUsageBuckets") if isinstance(usage_msg.get("dailyUsageBuckets"), list) else []

    primary_pct, primary_label, primary_reset = fill_window(limits.get("primary"))
    secondary_pct, secondary_label, secondary_reset = fill_window(limits.get("secondary"))
    recent_days, today_tokens = recent_days_from_buckets(buckets)

    plan = str(
        limits.get("planType")
        or account.get("planType")
        or account.get("type")
        or ""
    )

    try:
        balance = float(credits.get("balance") or 0)
    except (TypeError, ValueError):
        balance = 0.0

    return {
        "ready": True,
        "stale": False,
        "error": "",
        "email": str(account.get("email") or ""),
        "planType": plan,
        "primaryPercent": primary_pct,
        "primaryLabel": primary_label,
        "primaryResetsAt": primary_reset,
        "secondaryPercent": secondary_pct,
        "secondaryLabel": secondary_label,
        "secondaryResetsAt": secondary_reset,
        "creditsBalance": balance,
        "creditsUnlimited": bool(credits.get("unlimited")),
        "hasCredits": bool(credits.get("hasCredits")),
        "todayTokens": today_tokens,
        "recentDays": recent_days,
        "lifetimeTokens": int(summary.get("lifetimeTokens") or 0),
        "peakDailyTokens": int(summary.get("peakDailyTokens") or 0),
        "currentStreakDays": int(summary.get("currentStreakDays") or 0),
        "longestStreakDays": int(summary.get("longestStreakDays") or 0),
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
        cached["error"] = error
        emit(cached, 0)
    emit(empty_result(error=error), 1)


def main() -> None:
    try:
        result = fetch_usage()
        write_cache(result)
        emit(result, 0)
    except RuntimeError as exc:
        emit_failure(str(exc) or ERR_RPC_FAILED)
    except Exception as exc:
        emit_failure(str(exc) or type(exc).__name__)


if __name__ == "__main__":
    main()
