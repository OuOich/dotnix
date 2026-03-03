{ config, lib, ... }:

lib.mkMerge [
  {
    programs.kitty = {
      enable = true;

      settings = {
        allow_remote_control = true;
        listen_on = "unix:/tmp/kitty.sock";

        input_delay = 0;
        repaint_delay = 0;
        sync_to_monitor = true;

        background_opacity = 0.85;
        background_blur = 64;

        window_padding_width = "6 6";

        tab_bar_style = "powerline";

        cursor_trail = 1;
        cursor_trail_decay = "0.18 0.20";
        cursor_trail_start_threshold = 24;

        font_size = 10.0;
        disable_ligatures = "cursor";
      };

      keybindings = {
        "ctrl+shift+," = "previous_tab";
        "ctrl+shift+." = "next_tab";
        "ctrl+alt+shift+," = "move_tab_backward";
        "ctrl+alt+shift+." = "move_tab_forward";

        "ctrl+shift+;" = "launch --cwd=current --type=tab";
        "ctrl+shift+alt+;" = "launch --cwd=current --type=os-window";
      };
    };
  }

  (lib.mkIf (lib.strings.hasPrefix "catppuccin-" config.settings.theme.colorscheme) {
    stylix.targets.kitty.enable = false;
    catppuccin.kitty.enable = true;
  })
]
