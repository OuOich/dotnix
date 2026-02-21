{
  self,
  config,
  lib,
  ...
}:

let
  cfg = config.dotnix.configurations.common-sops;
in
{
  options.dotnix.configurations.common-sops = {
    enable = lib.mkEnableOption "Whether to enable the common sops-nix configuration.";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = self + /secrets/personal/${config.home.username}/default.yaml;

      age = {
        keyFile = lib.mkDefault "${config.home.homeDirectory}/.sops-nix/age-key.txt";
        # sshKeyPaths = lib.mkDefault [
        #   "${config.home.homeDirectory}/.ssh/id_ed25519"
        #   "${config.home.homeDirectory}/.ssh/id_rsa"
        # ];
      };
    };
  };
}
