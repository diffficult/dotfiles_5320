#!/usr/bin/env python3
"""
calendar_daemon.py - Warmind Waybar calendar state manager.

Usage:
  calendar_daemon.py --init              # Open: load current month, today selected
  calendar_daemon.py --prev              # Navigate to previous month
  calendar_daemon.py --next              # Navigate to next month
  calendar_daemon.py --select YYYY-MM-DD # Select a specific day
"""
import argparse
import calendar
import datetime
import json
import os
import sys
import tempfile
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]
CACHE_DIR = Path.home() / ".cache" / "quickshell" / "warmind" / "waybar" / "calendar"
LEGACY_CACHE_DIR = Path.home() / ".cache" / "waybar" / "gcal"
TOKEN_PATH = CACHE_DIR / "token.json"
LEGACY_TOKEN_PATH = LEGACY_CACHE_DIR / "token.json"
STATE_PATH = CACHE_DIR / "state.json"
PRIMARY_CREDS_PATH = Path.home() / ".config" / "warmind" / "waybar" / "calendar_cred.json"
LEGACY_CREDS_PATH = Path.home() / ".config" / "waybar" / "calendar_cred.json"
CREDS_PATH = Path(os.getenv("CALENDAR_CREDENTIALS_PATH", str(PRIMARY_CREDS_PATH if PRIMARY_CREDS_PATH.exists() else LEGACY_CREDS_PATH)))
CACHE_TTL_HOURS = 24

CALENDAR_COLORS = {
    "Personal": "#dd7878",
    "Birthdays": "#df8e1d",
    "Consultas y Estudios": "#1e66f5",
    "Family": "#40a02b",
    "Tasks": "#ea76cb",
}
DEFAULT_COLOR = "#cdd6f4"

CALENDAR_ICONS = {
    "Personal": "󰋚",
    "Birthdays": "󰃰",
    "Consultas y Estudios": "󰈷",
    "Family": "\uf0c0 ",
    "Tasks": "󰄱",
}
DEFAULT_ICON = "󰃭"


def get_credentials():
    """Return valid Google API credentials or None if setup needed."""
    creds = None
    token_source = TOKEN_PATH if TOKEN_PATH.exists() else LEGACY_TOKEN_PATH
    if token_source.exists():
        creds = Credentials.from_authorized_user_file(str(token_source), SCOPES)
    if creds and creds.valid:
        if token_source != TOKEN_PATH:
            CACHE_DIR.mkdir(parents=True, exist_ok=True)
            TOKEN_PATH.write_text(creds.to_json())
        return creds
    if creds and creds.expired and creds.refresh_token:
        try:
            creds.refresh(Request())
            CACHE_DIR.mkdir(parents=True, exist_ok=True)
            TOKEN_PATH.write_text(creds.to_json())
            return creds
        except Exception as exc:
            print(f"[calendar_daemon] token refresh failed: {exc}", file=sys.stderr)
    if not CREDS_PATH.exists():
        return None
    flow = InstalledAppFlow.from_client_secrets_file(str(CREDS_PATH), SCOPES)
    flow.redirect_uri = "http://localhost"
    auth_url, _ = flow.authorization_url(access_type="offline", prompt="consent")
    print(f"\nOpen this URL in your browser:\n\n{auth_url}\n", file=sys.stderr)
    print("After clicking Allow, the browser will try to load http://localhost — that page", file=sys.stderr)
    print("will fail to load (that's expected). Copy the FULL URL from the address bar", file=sys.stderr)
    print("(it starts with http://localhost/?code=...) and paste it here:\n", file=sys.stderr)
    redirect_response = input("Paste the full redirect URL: ").strip()
    os.environ["OAUTHLIB_INSECURE_TRANSPORT"] = "1"
    flow.fetch_token(authorization_response=redirect_response)
    creds = flow.credentials
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    TOKEN_PATH.write_text(creds.to_json())
    return creds


def fetch_month(year: int, month: int) -> dict:
    """Fetch all Google Calendar events for the given month and write cache."""
    creds = get_credentials()
    if creds is None:
        return {"error": "auth_required", "events": []}

    try:
        service = build("calendar", "v3", credentials=creds)
        start = datetime.datetime(year, month, 1, tzinfo=datetime.timezone.utc)
        next_month = month + 1 if month < 12 else 1
        next_year = year if month < 12 else year + 1
        end = datetime.datetime(next_year, next_month, 1, tzinfo=datetime.timezone.utc)

        calendars = service.calendarList().list().execute().get("items", [])
        all_events = []

        for cal in calendars:
            cal_name = cal.get("summary", "Unknown")
            result = (
                service.events()
                .list(
                    calendarId=cal["id"],
                    timeMin=start.isoformat(),
                    timeMax=end.isoformat(),
                    singleEvents=True,
                    orderBy="startTime",
                )
                .execute()
            )
            for event in result.get("items", []):
                raw_start = event["start"].get("dateTime", event["start"].get("date", ""))
                all_day = "dateTime" not in event["start"]
                if all_day:
                    event_date = raw_start[:10]
                    start_time = "All day"
                    end_time = ""
                else:
                    dt = datetime.datetime.fromisoformat(raw_start)
                    event_date = dt.strftime("%Y-%m-%d")
                    start_time = dt.strftime("%H:%M")
                    raw_end = event.get("end", {}).get("dateTime", "")
                    end_time = (
                        datetime.datetime.fromisoformat(raw_end).strftime("%H:%M")
                        if raw_end
                        else ""
                    )
                all_events.append(
                    {
                        "date": event_date,
                        "start_time": start_time,
                        "end_time": end_time,
                        "title": event.get("summary", "(No title)"),
                        "calendar": cal_name,
                        "color": CALENDAR_COLORS.get(cal_name, DEFAULT_COLOR),
                        "icon": CALENDAR_ICONS.get(cal_name, DEFAULT_ICON),
                        "all_day": all_day,
                    }
                )

        cache = {
            "fetched_at": datetime.datetime.now().isoformat(),
            "month": f"{year:04d}-{month:02d}",
            "events": all_events,
        }
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        cache_path = CACHE_DIR / f"events_{year:04d}-{month:02d}.json"
        cache_path.write_text(json.dumps(cache, indent=2))
        return cache
    except Exception as exc:
        print(f"[calendar_daemon] fetch failed: {exc}", file=sys.stderr)
        return {"error": "fetch_failed", "events": [], "fetched_at": datetime.datetime.now().isoformat(), "month": f"{year:04d}-{month:02d}"}


def load_month(year: int, month: int) -> dict:
    """Load month from cache, fetching if missing or older than CACHE_TTL_HOURS."""
    cache_path = CACHE_DIR / f"events_{year:04d}-{month:02d}.json"
    if cache_path.exists():
        data = json.loads(cache_path.read_text())
        age = datetime.datetime.now() - datetime.datetime.fromisoformat(data["fetched_at"])
        if age.total_seconds() < CACHE_TTL_HOURS * 3600:
            return data
    return fetch_month(year, month)


def build_days_grid(year: int, month: int, events: list, today: str | None = None) -> list:
    """Build a 7-column Mon-Sun grid of day cells with event dots."""
    if today is None:
        today = datetime.date.today().strftime("%Y-%m-%d")
    by_date: dict[str, list] = {}
    for event in events:
        by_date.setdefault(event["date"], []).append(event)

    cal = calendar.Calendar(firstweekday=0)
    days = []
    for dt in cal.itermonthdates(year, month):
        date_str = dt.strftime("%Y-%m-%d")
        day_events = by_date.get(date_str, [])
        seen_colors: set[str] = set()
        seen_icons: list[dict] = []
        for e in day_events:
            if e["color"] not in seen_colors:
                seen_colors.add(e["color"])
                seen_icons.append({
                    "icon": CALENDAR_ICONS.get(e.get("calendar", ""), DEFAULT_ICON),
                    "color": e["color"],
                })
        icons = seen_icons[:2]
        days.append(
            {
                "date": date_str,
                "date_num": str(dt.day),
                "in_month": dt.month == month,
                "is_today": date_str == today,
                "icons": icons,
                "overflow": max(0, len(seen_icons) - 2),
                "events": day_events,
            }
        )
    return days


def _month_label(year: int, month: int) -> str:
    return datetime.date(year, month, 1).strftime("%B %Y")


def _day_label(date_str: str) -> str:
    dt = datetime.date.fromisoformat(date_str)
    return dt.strftime("%A, %B %-d")


def load_state() -> dict:
    if STATE_PATH.exists():
        return json.loads(STATE_PATH.read_text())
    today = datetime.date.today()
    return {
        "current_month": today.strftime("%Y-%m"),
        "selected_day": today.strftime("%Y-%m-%d"),
    }


def write_state(year: int, month: int, selected_day: str) -> None:
    """Fetch/load month, build days grid, write state.json."""
    month_data = load_month(year, month)
    error = month_data.get("error")
    events = month_data.get("events", [])
    days = build_days_grid(year, month, events)
    weeks = [days[i:i + 7] for i in range(0, len(days), 7)]

    selected_events = []
    for e in events:
        if e["date"] == selected_day:
            ev = dict(e)
            if "icon" not in ev:
                ev["icon"] = CALENDAR_ICONS.get(ev.get("calendar", ""), DEFAULT_ICON)
            selected_events.append(ev)

    state = {
        "current_month": f"{year:04d}-{month:02d}",
        "month_label": _month_label(year, month),
        "selected_day": selected_day,
        "selected_day_label": _day_label(selected_day),
        "selected_events": selected_events,
        "loading": False,
        "stale": False,
        "error": error,
        "days": days,
        "weeks": weeks,
    }
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=CACHE_DIR, delete=False, suffix=".tmp") as f:
        f.write(json.dumps(state))
        tmp = f.name
    os.replace(tmp, STATE_PATH)


def action_init() -> None:
    today = datetime.date.today()
    write_state(today.year, today.month, today.strftime("%Y-%m-%d"))


def _carry_selected_day(state: dict, year: int, month: int) -> str:
    raw = state.get("selected_day", datetime.date.today().strftime("%Y-%m-%d"))
    try:
        old = datetime.date.fromisoformat(raw)
        day = min(old.day, calendar.monthrange(year, month)[1])
        return datetime.date(year, month, day).strftime("%Y-%m-%d")
    except Exception:
        return datetime.date(year, month, 1).strftime("%Y-%m-%d")


def action_prev() -> None:
    state = load_state()
    ym = state.get("current_month", datetime.date.today().strftime("%Y-%m"))
    year, month = int(ym[:4]), int(ym[5:7])
    month -= 1
    if month == 0:
        month, year = 12, year - 1
    write_state(year, month, _carry_selected_day(state, year, month))


def action_next() -> None:
    state = load_state()
    ym = state.get("current_month", datetime.date.today().strftime("%Y-%m"))
    year, month = int(ym[:4]), int(ym[5:7])
    month += 1
    if month == 13:
        month, year = 1, year + 1
    write_state(year, month, _carry_selected_day(state, year, month))


def action_select(date_str: str) -> None:
    year, month = int(date_str[:4]), int(date_str[5:7])
    current_month = f"{year:04d}-{month:02d}"
    state = load_state()

    if state.get("current_month") == current_month and state.get("weeks"):
        selected_events = []
        for week in state["weeks"]:
            for day in week:
                if day["date"] == date_str:
                    selected_events = list(day.get("events", []))
                    break
        for ev in selected_events:
            if "icon" not in ev:
                ev["icon"] = CALENDAR_ICONS.get(ev.get("calendar", ""), DEFAULT_ICON)
        state["selected_day"] = date_str
        state["selected_day_label"] = _day_label(date_str)
        state["selected_events"] = selected_events
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(mode="w", dir=CACHE_DIR, delete=False, suffix=".tmp") as f:
            f.write(json.dumps(state))
            tmp = f.name
        os.replace(tmp, STATE_PATH)
        return

    write_state(year, month, date_str)


def main() -> None:
    parser = argparse.ArgumentParser(description="Warmind Waybar calendar state daemon")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--init", action="store_true", help="Initialize to today")
    group.add_argument("--prev", action="store_true", help="Go to previous month")
    group.add_argument("--next", action="store_true", help="Go to next month")
    group.add_argument("--select", metavar="YYYY-MM-DD", help="Select a specific day")
    args = parser.parse_args()

    if args.init:
        action_init()
    elif args.prev:
        action_prev()
    elif args.next:
        action_next()
    elif args.select:
        action_select(args.select)


if __name__ == "__main__":
    main()
