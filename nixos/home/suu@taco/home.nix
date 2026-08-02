{ osConfig, ... }:

{
  home.username = osConfig.users.users.suu.name;
  home.homeDirectory = osConfig.users.users.suu.home;

  imports = [
    ../suu/base

    ../suu/defaults.nix
    ../suu/fonts
    ../suu/stylix
    ../suu/catppuccin.nix
    ../suu/wallpapers.nix

    ../suu/services/udiskie

    ../suu/desktop/niri
    ../suu/desktop/gtk
    ../suu/desktop/qt
    ../suu/desktop/noctalia
    ../suu/desktop/im

    ../suu/programs/bat
    ../suu/programs/copyq
    ../suu/programs/dasel
    ../suu/programs/devenv
    ../suu/programs/direnv
    ../suu/programs/dotnvim
    ../suu/programs/duf
    ../suu/programs/dust
    ../suu/programs/eza
    ../suu/programs/fastfetch
    ../suu/programs/fd
    ../suu/programs/fish
    ../suu/programs/fzf
    ../suu/programs/gh
    ../suu/programs/git
    ../suu/programs/gpg
    ../suu/programs/jq
    ../suu/programs/kitty
    ../suu/programs/lazygit
    ../suu/programs/matugen
    ../suu/programs/opencode
    ../suu/programs/ouch
    ../suu/programs/procs
    ../suu/programs/ripgrep
    ../suu/programs/spotify
    ../suu/programs/starship
    ../suu/programs/tealdeer
    ../suu/programs/telegram
    ../suu/programs/veracrypt
    ../suu/programs/wakatime
    ../suu/programs/yazi
    ../suu/programs/yq
    ../suu/programs/zen-browser
    ../suu/programs/zoxide

    # -------------------------

    ./settings.nix

    ./impermanence.nix

    ./security/ssh

    ./desktop/niri
    ./desktop/noctalia
  ];

  dotnix.configurations = {
    common-sops.enable = true;
  };

  home.stateVersion = "26.05";
}
