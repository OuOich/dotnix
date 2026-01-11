{ config, lib, ... }:

let
  cfg = config.dotnix.configurations.trustedGroup;
in
{
  options.dotnix.configurations.trustedGroup = {
    enable = lib.mkEnableOption "Whether to enable `trusted` group configuration.";
  };

  config = lib.mkIf cfg.enable {
    users.groups.trusted = lib.mkDefault {
      gid = lib.mkDefault 997;

      members = [
        "root"
      ];
    };
  };
}
