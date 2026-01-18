{
  dotnix,
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      # `nix` and `nix-shell` wrapper for fish shell
      ${pkgs.nix-your-shell}/bin/nix-your-shell fish | source
    '';

    shellAliases = {
      ip = "ip -c";
      grep = "grep --color=auto";
    };

    shellAbbrs = lib.mkMerge [
      {
        i = "fastfetch";
        wlc = "wl-copy";
      }

      (lib.mkIf config.programs.neovim.enable {
        e = "nvim";
      })

      (lib.mkIf config.programs.bat.enable {
        b = "bat";
      })

      (lib.mkIf config.programs.git.enable {
        g = "git";
      })

      (lib.mkIf config.programs.eza.enable {
        l = "eza";
        ls = "eza -a";
        la = "eza -a";
        ll = "eza -la";
        lt = "eza -Ta";
        llt = "eza -lTa";
      })
    ];
  };

  xdg.configFile =
    let
      subst = src: dotnix.lib.substituteDir { inherit src vars; };

      vars = {
        fastfetch = "${pkgs.fastfetch}/bin/fastfetch";
      };
    in
    {
      "fish/conf.d" = {
        source = subst ./conf.d;
        recursive = true;
      };
      "fish/functions" = {
        source = subst ./functions;
        recursive = true;
      };
    };
}
