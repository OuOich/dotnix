{ config, lib, ... }:

let
  cfg = config.dotnix.configurations.common-pipewire;
in
{
  options.dotnix.configurations.common-pipewire = {
    enable = lib.mkEnableOption "Whether to enable the common pipewire configuration.";
  };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = lib.mkDefault true;
    services.pulseaudio.enable = lib.mkDefault false;

    services.pipewire = {
      enable = lib.mkDefault true;

      audio.enable = lib.mkDefault true;

      alsa.enable = lib.mkDefault true;
      alsa.support32Bit = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
      jack.enable = lib.mkDefault true;

      extraConfig.pipewire = {
        "10-clock-rate" = lib.mkDefault {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [
              44100
              48000
              88200
              96000
              176400
              192000
            ];
          };
        };
      };

      wireplumber.enable = lib.mkDefault true;
    };
  };
}
