{ config, lib, ... }:

let
  cfg = config.dotnix.templates.generalDesktop;
in
{
  options.dotnix.templates.generalDesktop = {
    enable = lib.mkEnableOption "Whether to enable general desktop template.";
  };

  config = lib.mkIf cfg.enable {
    dotnix.configurations = {
      trustedGroup.enable = lib.mkDefault true;
      commonNix.enable = lib.mkDefault true;
      commonSudoRs.enable = lib.mkDefault true;
    };

    boot.loader = {
      grub = {
        enable = lib.mkDefault true;

        device = lib.mkDefault "nodev";
        efiSupport = lib.mkDefault true;
        efiInstallAsRemovable = lib.mkDefault true;
      };

      efi.efiSysMountPoint = lib.mkDefault "/boot";
    };

    networking = {
      useDHCP = lib.mkDefault true;
      nameservers = lib.mkDefault [
        "1.1.1.1"
        "8.8.8.8"
      ];

      networkmanager = {
        enable = lib.mkDefault true;

        settings = {
          connectivity.uri = lib.mkDefault "http://nmcheck.gnome.org/check_network_status.txt";
        };
      };
    };

    programs.vim = {
      enable = lib.mkDefault true;

      defaultEditor = lib.mkDefault true;
    };
  };
}
