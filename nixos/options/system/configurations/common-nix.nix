{
  dotnix,
  config,
  lib,
  ...
}:

let
  cfg = config.dotnix.configurations.common-nix;
in
{
  options.dotnix.configurations.common-nix = {
    enable = lib.mkEnableOption "Whether to enable the common Nix configuration.";

    trustUsersInTrustedGroup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to add users in the `trusted` group to `nix.settings.trusted-users`.";
    };
  };

  config = lib.mkIf cfg.enable {
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        trusted-users = lib.mkIf cfg.trustUsersInTrustedGroup (
          dotnix.lib.utils.getUserNamesInGroup config config.users.groups.trusted.name
        );

        auto-optimise-store = lib.mkDefault true;
      };

      gc = {
        automatic = lib.mkDefault true;
        dates = lib.mkDefault "weekly";
        options = lib.mkDefault "--delete-older-than 7d";
      };
    };
  };
}
