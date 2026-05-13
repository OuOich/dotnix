{
  programs.noctalia-shell = {
    enable = true;

    settings = {
      bar = {
        position = "bottom";

        widgets = {
          left = [
            {
              id = "ControlCenter";
            }

            {
              id = "Workspace";
            }

            {
              id = "MediaMini";
            }
          ];

          center = [
            {
              id = "ActiveWindow";

              colorizeIcons = false;
            }
          ];

          right = [
            {
              id = "Tray";

              blacklist = [
                "Fcitx*"
                "Rime"
              ];
            }

            {
              id = "NotificationHistory";
            }

            {
              id = "Volume";
            }

            {
              id = "Brightness";
            }

            {
              id = "Battery";

              displayMode = "icon-hover";
            }

            {
              id = "SystemMonitor";
            }

            {
              id = "Clock";
            }
          ];
        };
      };
    };
  };
}
