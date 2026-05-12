{ osConfig, ... }:

{
  home.username = osConfig.users.users.cheng.name;
  home.homeDirectory = osConfig.users.users.cheng.home;

  imports = [
    ./impermanence.nix

    ./settings.nix

    # -------------------------

    ../cheng/defaults.nix
    ../cheng/fonts
    ../cheng/stylix
    ../cheng/catppuccin.nix
    ../cheng/wallpapers.nix
    ../cheng/im

    ../cheng/desktop/niri
    ../cheng/desktop/noctalia

    ../cheng/programs/bat
    ../cheng/programs/dasel
    ../cheng/programs/direnv
    ../cheng/programs/dotnvim
    ../cheng/programs/duf
    ../cheng/programs/dust
    ../cheng/programs/eza
    ../cheng/programs/fastfetch
    ../cheng/programs/fd
    ../cheng/programs/fish
    ../cheng/programs/fzf
    ../cheng/programs/gh
    ../cheng/programs/git
    ../cheng/programs/gpg
    ../cheng/programs/jq
    ../cheng/programs/kitty
    ../cheng/programs/lazygit
    ../cheng/programs/matugen
    ../cheng/programs/ouch
    ../cheng/programs/procs
    ../cheng/programs/ripgrep
    ../cheng/programs/starship
    ../cheng/programs/tealdeer
    ../cheng/programs/yazi
    ../cheng/programs/yq
    ../cheng/programs/zen-browser
    ../cheng/programs/zoxide

    # -------------------------

    ./security/ssh

    ./desktop/niri
    ./desktop/noctalia
  ];

  dotnix.configurations = {
    common-sops.enable = true;
  };

  home.stateVersion = "26.05";
}
