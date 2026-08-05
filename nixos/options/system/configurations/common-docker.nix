{
  dotnix,
  config,
  options,
  lib,
  ...
}:

let
  cfg = config.dotnix.configurations.common-docker;
in
{
  options.dotnix.configurations.common-docker = {
    enable = lib.mkEnableOption "Whether to enable the Docker container runtime.";

    trustUsersInTrustedGroup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to add users in the `trusted` group to the `docker` group.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        virtualisation.docker = {
          enable = true;

          autoPrune = {
            enable = lib.mkDefault true;
            dates = lib.mkDefault "weekly";
          };

          daemon.settings = {
            "log-driver" = lib.mkDefault "journald";
          };
        };

        users.groups.docker.members = lib.mkIf cfg.trustUsersInTrustedGroup (
          dotnix.lib.utils.getUserNamesInGroup config config.users.groups.trusted.name
        );
      }

      (lib.mkIf (options.environment ? persistence) {
        environment.persistence."/persist" = {
          directories = [
            "/var/lib/docker"
          ];
        };
      })
    ]
  );
}
