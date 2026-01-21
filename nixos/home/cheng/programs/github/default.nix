{ config, ... }:

{
  programs.gh = {
    enable = true;

    settings = {
      editor = config.home.sessionVariables.EDITOR or "nano";
    };
  };
}
