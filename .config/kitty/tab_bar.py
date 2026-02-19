# pyright: reportMissingImports=false
from datetime import datetime

from kitty.boss import get_boss
from kitty.fast_data_types import Screen, add_timer, get_options
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    Formatter,
    TabBarData,
    as_rgb,
    draw_attributed_string,
    draw_title,
)
from kitty.utils import color_as_int

opts = get_options()

SEPARATOR_SYMBOL, SOFT_SEPARATOR_SYMBOL = ("", "")
LEFT_SEPARATOR_SYMBOL, LEFT_SOFT_SEPARATOR_SYMBOL = ("", "")

RIGHT_MARGIN = 1
REFRESH_TIME = 1

ICON = "  "

# Hard-coded active tab colors
ACTIVE_TAB_BG = as_rgb((114 << 16) | (135 << 8) | 253)  # #7287fd
ACTIVE_TAB_FG = as_rgb((24 << 16) | (25 << 8) | 38)  # #181926

# Time foreground color
TIME_FG = as_rgb((202 << 16) | (211 << 8) | 245)  # #cad3f5

icon_fg = as_rgb(color_as_int(opts.color16))
icon_bg = as_rgb(color_as_int(opts.color8))


timer_id = None
right_status_length = -1


def _draw_icon(screen: Screen, index: int) -> int:
    if index != 1:
        return 0
    fg, bg = screen.cursor.fg, screen.cursor.bg
    screen.cursor.fg = icon_fg
    screen.cursor.bg = icon_bg
    screen.draw(ICON)
    screen.cursor.fg, screen.cursor.bg = fg, bg
    screen.cursor.x = len(ICON)
    return screen.cursor.x


def _draw_left_status(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    if screen.cursor.x >= screen.columns - right_status_length:
        return screen.cursor.x

    tab_bg = screen.cursor.bg
    tab_fg = screen.cursor.fg
    default_bg = as_rgb(int(draw_data.default_bg))

    # Hard-code active tab appearance
    if tab.is_active:
        screen.cursor.bg = ACTIVE_TAB_BG
        screen.cursor.fg = ACTIVE_TAB_FG
        screen.cursor.bold = True
        tab_bg = ACTIVE_TAB_BG
        tab_fg = ACTIVE_TAB_FG
    else:
        screen.cursor.bold = False

    if extra_data.next_tab:
        next_tab_bg = (
            ACTIVE_TAB_BG
            if extra_data.next_tab.is_active
            else as_rgb(draw_data.tab_bg(extra_data.next_tab))
        )
        needs_soft_separator = next_tab_bg == tab_bg
    else:
        next_tab_bg = default_bg
        needs_soft_separator = False

    if screen.cursor.x <= len(ICON):
        screen.cursor.x = len(ICON)

    screen.draw(" ")
    screen.cursor.bg = tab_bg
    draw_title(draw_data, screen, tab, index)

    if not needs_soft_separator:
        screen.draw(" ")
        screen.cursor.fg = tab_bg
        screen.cursor.bg = next_tab_bg
        screen.draw(SEPARATOR_SYMBOL)
    else:
        prev_fg = screen.cursor.fg
        if tab_bg == tab_fg:
            screen.cursor.fg = default_bg
        elif tab_bg != default_bg:
            c1 = draw_data.inactive_bg.contrast(draw_data.default_bg)
            c2 = draw_data.inactive_bg.contrast(draw_data.inactive_fg)
            if c1 < c2:
                screen.cursor.fg = default_bg
        screen.draw(" " + SOFT_SEPARATOR_SYMBOL)
        screen.cursor.fg = prev_fg

    return screen.cursor.x


def _draw_right_status(
    draw_data: DrawData, screen: Screen, is_last: bool, cells: list[str]
) -> int:
    if not is_last or not cells:
        return 0

    draw_attributed_string(Formatter.reset, screen)

    total_length = sum(len(s) for s in cells) + len(
        cells
    )  # separators between + left separator
    start_x = screen.columns - RIGHT_MARGIN - total_length

    # Avoid overwriting if there is no room
    if start_x <= 0:
        return 0

    time_bg = as_rgb(int(draw_data.inactive_bg))
    date_bg = ACTIVE_TAB_BG

    bg_colors = [time_bg, date_bg]
    fg_colors = [TIME_FG, ACTIVE_TAB_FG]
    bold_flags = [False, True]

    x = start_x

    # Left separator pointing into first block
    screen.cursor.x = x
    screen.cursor.bg = 0
    screen.cursor.fg = bg_colors[0]
    screen.cursor.bold = False
    screen.draw(LEFT_SEPARATOR_SYMBOL)
    x = screen.cursor.x

    for i, text in enumerate(cells):
        screen.cursor.x = x
        screen.cursor.bg = bg_colors[i]
        screen.cursor.fg = fg_colors[i]
        screen.cursor.bold = bold_flags[i]
        screen.draw(text)
        x = screen.cursor.x

        if i < len(cells) - 1:
            # Separator between blocks (points left)
            screen.cursor.bg = bg_colors[i]
            screen.cursor.fg = bg_colors[i + 1]
            screen.cursor.bold = False
            screen.draw(LEFT_SEPARATOR_SYMBOL)
            x = screen.cursor.x

    screen.cursor.bold = False
    screen.cursor.bg = 0
    screen.cursor.fg = 0

    return x


def _redraw_tab_bar(_):
    tm = get_boss().active_tab_manager
    if tm is not None:
        tm.mark_tab_bar_dirty()


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    global timer_id
    global right_status_length

    if timer_id is None:
        timer_id = add_timer(_redraw_tab_bar, REFRESH_TIME, True)

    clock = datetime.now().strftime(" %H:%M") + " "
    date = datetime.now().strftime(" %d.%m.%Y") + " "

    cells = [clock, date]

    right_status_length = RIGHT_MARGIN + sum(len(s) for s in cells) + len(cells)

    _draw_icon(screen, index)
    _draw_left_status(
        draw_data,
        screen,
        tab,
        before,
        max_title_length,
        index,
        is_last,
        extra_data,
    )
    _draw_right_status(draw_data, screen, is_last, cells)
    return screen.cursor.x
