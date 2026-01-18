{
  config,
  lib,
  ...
}:

let
  cfg = config.dotnix.configurations.common-sudo-rs;
in
{
  options.dotnix.configurations.common-sudo-rs = {
    enable = lib.mkEnableOption "Whether to enable the common sudo-rs configuration.";

    trustedGroupNopasswd = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether users in the `trusted` group are permitted to execute all commands without a password.";
    };
  };

  config = lib.mkIf cfg.enable {
    security.sudo-rs = {
      enable = lib.mkDefault true;

      extraRules = [
        (lib.mkIf cfg.trustedGroupNopasswd {
          groups = with config.users.groups; [ trusted.name ];

          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        })
      ];
    };
  };
}
