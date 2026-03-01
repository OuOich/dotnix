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
      sddm-astronaut = pkgs.sddm-astronaut.override {
        embeddedTheme = "hyprland_kath";
        themeConfig = {
          AllowUppercaseLettersInUsernames = "true";
        };
      };
    in
    {
      services.displayManager.sddm = {
        enable = true;
        package = lib.mkForce pkgs.kdePackages.sddm;
        extraPackages = [ sddm-astronaut ];

        wayland.enable = true;

        enableHidpi = true;
        theme = "sddm-astronaut-theme";
      };

      environment.systemPackages = with pkgs; [
        sddm-astronaut
        kdePackages.qtmultimedia
      ];
    }
  )

  (lib.mkIf (options.environment ? persistence) {
    environment.persistence.${config.fileSystems."/persist".mountPoint} = {
      files = [
        "/var/lib/sddm/state.conf"
      ];
    };
  })
]
