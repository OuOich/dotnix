{ config, lib, ... }:

let
  cfg = config.dotnix.configurations.qemu-guest;
in
{
  options.dotnix.configurations.qemu-guest = {
    enable = lib.mkEnableOption "Whether to enable qemu virtual machine configuration.";
  };

  config = lib.mkIf cfg.enable {
    services.spice-vdagentd.enable = lib.mkDefault true;
    services.qemuGuest.enable = lib.mkDefault true;
  };
}
