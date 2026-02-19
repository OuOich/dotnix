{ osConfig, ... }:

{
  home.username = osConfig.users.users.cheng.name;
  home.homeDirectory = osConfig.users.users.cheng.home;

  imports = [
    ../cheng/stylix
    ../cheng/catppuccin

    ../cheng/desktop/niri

    ../cheng/programs/bat
    ../cheng/programs/dotnvim
    ../cheng/programs/eza
    ../cheng/programs/fastfetch
    ../cheng/programs/fish
    ../cheng/programs/git
    ../cheng/programs/github
    ../cheng/programs/gpg
    ../cheng/programs/lazygit

    # -------------------------

    ./settings.nix
  ];

  home.stateVersion = "26.05";
}
