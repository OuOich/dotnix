{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.dotnix.templates.general-server;
in
{
  options.dotnix.templates.general-server = {
    enable = lib.mkEnableOption "Whether to enable general server template.";
  };

  config = lib.mkIf cfg.enable {
    dotnix.configurations = {
      common-nix.enable = lib.mkDefault true;
    };

    boot.loader.grub.enable = lib.mkDefault true;

    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;
    boot.kernelParams = [ "console=ttyS0,115200n8" ];

    networking = {
      useDHCP = lib.mkDefault true;
      nameservers = lib.mkDefault [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };

    services.fail2ban = {
      enable = lib.mkDefault true;

      maxretry = lib.mkDefault 3;
      bantime = lib.mkDefault "1h";
    };

    programs.vim = {
      enable = lib.mkDefault true;
      defaultEditor = lib.mkDefault true;
    };

    programs.git = {
      enable = lib.mkDefault true;
    };

    environment.systemPackages = with pkgs; [
      curl
      wget
      rsync
    ];

    environment.enableAllTerminfo = lib.mkDefault true;
  };
}
