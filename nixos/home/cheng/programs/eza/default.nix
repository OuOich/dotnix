{ config, lib, ... }:

{
  programs.eza = {
    enable = true;

    colors = "auto";
    icons = "auto";
    git = lib.mkIf config.programs.git.enable true;
  };
}
