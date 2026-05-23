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

              showVisualizer = true;
              visualizerType = "mirrored";
              showArtistFirst = false;
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

              colorizeIcons = false;
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
