import subprocess
import core.module
import core.widget


class Module(core.module.Module):
    def __init__(self, config, theme):
        super().__init__(config, theme, [])

    def update(self):
        self.clear_widgets()
        try:
            output = subprocess.check_output("xset q", shell=True).decode()
            capslock = "Caps Lock:   on" in output
            numlock = "Num Lock:    on" in output
            if capslock or numlock:
                widget = self.add_widget(name="capslock")
                # widget.full_text("⇪") # 󰪛 ⇪   󰎶 󰲬 󰄛
                num_indicator = " 󰄛 "
                cap_indicator = "⇪"
                full_text = f"{num_indicator}{cap_indicator}" if capslock and numlock \
                    else cap_indicator if capslock else num_indicator
                widget.full_text(full_text)
        except Exception:
            pass

    def state(self, _widget):
        try:
            output = subprocess.check_output("xset q", shell=True).decode()
            capslock = "Caps Lock:   on" in output
            numlock = "Num Lock:    on" in output
            if capslock or numlock:
                return ["warning"]
        except Exception:
            pass
        return []
