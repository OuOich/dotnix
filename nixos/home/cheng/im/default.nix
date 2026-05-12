{
  config,
  options,
  pkgs,
  lib,
  ...
}:

lib.mkMerge [
  (
    let
      rimeAddon = pkgs.fcitx5-rime.override {
        rimeDataPkgs = [ pkgs.rime-ice ];
      };
    in
    {
      i18n.inputMethod = {
        enable = true;

        type = "fcitx5";

        fcitx5 = {
          waylandFrontend = true;

          addons = [ rimeAddon ];

          settings = {
            inputMethod = {
              GroupOrder."0" = "Default";

              "Groups/0" = {
                Name = "Default";
                "Default Layout" = "us";
                DefaultIM = "rime";
              };

              # "Groups/0/Items/0".Name = "keyboard-us";
              "Groups/0/Items/0".Name = "rime";
            };
          };
        };
      };

      xdg.dataFile."fcitx5/rime/default.custom.yaml" = {
        text = /* yaml */ ''
          patch:
            __include: rime_ice_suggestion:/

            menu:
              page_size: 9
        '';

        onChange = ''
          ${pkgs.systemd}/bin/systemd-run --user --collect --quiet ${pkgs.writeShellScript "rime-deploy" ''
            set -u

            rimeDataDir="${config.xdg.dataHome}/fcitx5/rime"

            if [ -d "$rimeDataDir" ]; then
              rm -rf "$rimeDataDir/build"
              ${pkgs.librime}/bin/rime_deployer --build "$rimeDataDir" "${rimeAddon}/share/rime-data" "$rimeDataDir/build"
            fi

            ${pkgs.systemd}/bin/systemctl --user try-restart fcitx5-daemon.service || true
          ''} || true
        '';
      };
    }
  )

  (lib.optionalAttrs (options.home ? persistence) {
    home.persistence."/persist" = {
      directories = [
        ".local/share/fcitx5"
      ];
    };
  })
]
