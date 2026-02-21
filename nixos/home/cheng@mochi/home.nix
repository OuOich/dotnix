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
    ../cheng/programs/starship

    # -------------------------

    ./settings.nix

    ./security/ssh
  ];

  dotnix.configurations = {
    common-sops.enable = true;
  };

  home.stateVersion = "26.05";
}
