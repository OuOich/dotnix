{ config, lib, ... }:

let
  cfg = config.dotnix.configurations.trusted-group;
in
{
  options.dotnix.configurations.trusted-group = {
    enable = lib.mkEnableOption "Whether to enable `trusted` group configuration.";
  };

  config = lib.mkIf cfg.enable {
    users.groups.trusted = lib.mkDefault {
      gid = lib.mkDefault 997;

      members = with config.users.users; [
        root.name
      ];
    };
  };
}
