{ pkgs, ... }:

{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  xdg.portal.config.niri = {
    default = [
      "gnome"
      "gtk"
    ];

    "org.freedesktop.impl.portal.Access" = [ "gtk" ];
    "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  };

  systemd.user.services.xdg-desktop-portal.after = [ "niri.service" ];
  systemd.user.services.xdg-desktop-portal-gnome.after = [ "niri.service" ];
}
