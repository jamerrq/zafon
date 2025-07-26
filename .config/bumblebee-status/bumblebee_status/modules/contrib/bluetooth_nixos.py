"""Displays bluetooth status for NixOS using bluetoothctl. Left mouse click launches manager app `blueman-manager`,
right click toggles bluetooth.

Parameters:
    * bluetooth_nixos.manager : application to launch on click (blueman-manager)

"""

import os
import re
import logging

import core.module
import core.widget
import core.input

import util.cli
import util.format
import util.popup


class Module(core.module.Module):
    def __init__(self, config, theme):
        super().__init__(config, theme, core.widget.Widget(self.status))

        self.manager = self.parameter("manager", "blueman-manager")
        self._status = "Off"

        core.input.register(self, button=core.input.LEFT_MOUSE, cmd=self.manager)
        core.input.register(self, button=core.input.RIGHT_MOUSE, cmd=self._toggle)

    def status(self, widget):
        """Get status."""
        return self._status

    def update(self):
        """Update current state."""
        try:
            cmd = "bluetoothctl show | grep 'Powered:'"
            result = util.cli.execute(cmd)
            if "yes" in result.lower():
                self._status = "On"
            else:
                self._status = "Off"
        except Exception:
            self._status = "?"

    def _toggle(self, widget=None):
        """Toggle bluetooth state."""
        if self._status == "On":
            cmd = "bluetoothctl power off"
        else:
            cmd = "bluetoothctl power on"

        logging.debug("bt: toggling bluetooth")
        util.cli.execute(cmd, ignore_errors=True)

    def state(self, widget):
        """Get current state."""
        state = []

        if self._status == "?":
            state = ["unknown"]
        elif self._status == "On":
            state = ["ON"]
        else:
            state = ["OFF"]

        return state
