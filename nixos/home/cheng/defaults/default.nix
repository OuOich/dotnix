{
  config,
  lib,
  ...
}:

{
  home.sessionVariables = {
    PAGER = if config.programs.bat.enable then "bat" else "less";

    EDITOR =
      if (config.programs.neovim.enable || config.programs.dotnvim.enable or false) then
        "nvim"
      else if config.programs.emacs.enable then
        "emacs"
      else
        "nano";

    TERMINAL =
      with config.programs;
      if kitty.enable then
        "kitty"
      else if wezterm.enable then
        "wezterm"
      else if alacritty.enable then
        "alacritty"
      else if foot.enable then
        "foot"
      else
        null;
  };

  xdg.mimeApps = {
    enable = true;

    defaultApplications =
      let
        defaultEditor = [
          (lib.mkIf (config.programs.neovim.enable || config.programs.dotnvim.enable or false) "nvim.desktop")
        ];
      in
      {
        "text/plain" = defaultEditor;
        "text/markdown" = defaultEditor;
      };
  };

  xdg.configFile."mimeapps.list".force = true;
}
