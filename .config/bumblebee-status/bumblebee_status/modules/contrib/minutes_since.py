# pylint: disable=C0111,R0903

import core.module
import core.widget
import core.input

import os
import time
from datetime import datetime

SAVE_PATH = "/tmp/last_smoke_time"

def int_to_roman(num):
    roman_map = [
        (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
        (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
        (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")
    ]
    result = ""
    for (arabic, roman) in roman_map:
        while num >= arabic:
            result += roman
            num -= arabic
    return result


class Module(core.module.Module):
    def __init__(self, config, theme):
        super().__init__(config, theme, core.widget.Widget(name="smoke_timer"))

        self.meta = int(self.parameter("goal", 64))  # default goal: 64 hours
        self.reset_if_needed()

        core.input.register(self, button=core.input.RIGHT_MOUSE, 
        cmd=self.reset_time)

    def reset_time(self, _widget=None):
        with open(SAVE_PATH, "w") as f:
            f.write(str(int(time.time())))
        self._last_time = time.time()

    def reset_if_needed(self):
        if not os.path.exists(SAVE_PATH):
            self.reset_time()
        else:
            with open(SAVE_PATH, "r") as f:
                self._last_time = int(f.read().strip())

    def update(self):
        now = time.time()
        delta_seconds = int(now - self._last_time)

        hours = delta_seconds // 3600
        minutes = (delta_seconds % 3600) // 60
        seconds = delta_seconds % 60

        roman_goal = int_to_roman(self.meta)
        percent = min(100, int((hours / self.meta) * 100))

        self.widget("smoke_timer").full_text(f"{hours}h{minutes}m{seconds}s / {roman_goal} ({percent}%)")
