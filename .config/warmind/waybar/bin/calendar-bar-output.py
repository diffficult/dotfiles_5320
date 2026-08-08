#!/usr/bin/env python3
import datetime
import json
import sys

from calendar_daemon import load_month

COUNT_COLOR = "#f38ba8"
EMPTY_COLOR = "#6c7086"
ERROR_COLOR = "#f38ba8"
CAL_GLYPH = ""


def emit(payload: dict) -> None:
    print(json.dumps(payload, ensure_ascii=False))


def main() -> int:
    today = datetime.date.today()
    month = load_month(today.year, today.month)
    if month.get("error"):
        emit({
            "text": f"<span size='14pt'>{CAL_GLYPH} <span color='{ERROR_COLOR}'>!</span></span>",
            "alt": "error",
            "class": "calendar-error",
            "tooltip": "Calendar backend unavailable",
        })
        return 0

    events = [e for e in month.get("events", []) if e.get("date") == today.strftime("%Y-%m-%d")]
    count = len(events)

    if count == 0:
        emit({
            "text": f"<span size='14pt'>{CAL_GLYPH} <span color='{EMPTY_COLOR}'>0</span></span>",
            "alt": "0",
            "class": "calendar-empty",
            "tooltip": "No events today",
        })
        return 0

    tooltip_lines = []
    for event in events:
        start = event.get("start_time") or ""
        title = event.get("title") or "(No title)"
        tooltip_lines.append(f"{start}  {title}".rstrip())

    emit({
        "text": f"<span size='14pt'>{CAL_GLYPH} <span color='{COUNT_COLOR}'>{count}</span></span>",
        "alt": str(count),
        "class": "calendar-active",
        "tooltip": "\n".join(tooltip_lines),
    })
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
