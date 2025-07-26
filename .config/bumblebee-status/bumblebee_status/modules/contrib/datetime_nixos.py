"""Displays the current date and time for NixOS.

Parameters:
    * datetime_nixos.format: strftime()-compatible formatting string
    * datetime_nixos.locale: locale to use rather than the system default
"""

from __future__ import absolute_import
import datetime
import locale

import core.module
import core.widget
import core.input


class Module(core.module.Module):
    def __init__(self, config, theme, dtlibrary=None):
        super().__init__(config, theme, core.widget.Widget(self.full_text))

        core.input.register(self, button=core.input.LEFT_MOUSE, cmd="calendar")
        self.dtlibrary = dtlibrary or datetime

    def set_locale(self):
        l = self.default_locale()
        if not l or l == (None, None):
            l = ("en_US", "UTF-8")
        lcl = self.parameter("locale", ".".join(l))
        try:
            locale.setlocale(locale.LC_ALL, lcl.split("."))
        except Exception as e:
            locale.setlocale(locale.LC_ALL, ("en_US", "UTF-8"))

    def default_format(self):
        return "%x %X"

    def default_locale(self):
        return locale.getdefaultlocale()

    def full_text(self, widget):
        self.set_locale()
        enc = locale.getpreferredencoding()
        fmt = self.parameter("format", self.default_format())

        # get the current datetime
        now = self.dtlibrary.datetime.now()

        # get the week number (ISO week number)
        try:
            week_number = int(now.strftime("%V"))
            # convert to roman numeral
            roman_week = self.int_to_roman(week_number)
            # replace custom placeholder in format
            fmt = fmt.replace("{roman_week}", roman_week)
        except Exception:
            # If there's any error with the roman week, just replace with the numeric week
            fmt = fmt.replace("{roman_week}", now.strftime("%V"))

        try:
            retval = now.strftime(fmt)
        except Exception:
            # Fallback to a simpler format if there's an error
            retval = now.strftime("%Y-%m-%d %H:%M")

        if hasattr(retval, "decode"):
            try:
                return retval.decode(enc)
            except Exception:
                return retval
        return retval

    def int_to_roman(self, num):
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
