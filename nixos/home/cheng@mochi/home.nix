{ osConfig, ... }:

{
  home.username = osConfig.users.users.cheng.name;
  home.homeDirectory = osConfig.users.users.cheng.home;

  imports = [
    ../cheng/base

    ../cheng/defaults.nix
    ../cheng/fonts
    ../cheng/stylix
    ../cheng/catppuccin.nix
    ../cheng/wallpapers.nix

    ../cheng/desktop/plasma
    ../cheng/desktop/gtk
    ../cheng/desktop/qt
    ../cheng/desktop/niri
    ../cheng/desktop/noctalia
    ../cheng/desktop/im

    ../cheng/programs/bat
    ../cheng/programs/copyq
    ../cheng/programs/dasel
    ../cheng/programs/devenv
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
    ../cheng/programs/opencode
    ../cheng/programs/ouch
    ../cheng/programs/procs
    ../cheng/programs/ripgrep
    ../cheng/programs/spotify
    ../cheng/programs/starship
    ../cheng/programs/tealdeer
    ../cheng/programs/telegram
    ../cheng/programs/wakatime
    ../cheng/programs/yazi
    ../cheng/programs/yq
    ../cheng/programs/zen-browser
    ../cheng/programs/zoxide

    # -------------------------

    ./settings.nix

    ./impermanence.nix

    ./security/ssh
  ];

  dotnix.configurations = {
    common-sops.enable = true;
  };

  home.stateVersion = "26.05";
}
