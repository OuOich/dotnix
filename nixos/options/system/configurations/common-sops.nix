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
      defaultSopsFile = self + /secrets/nixos/${config.networking.hostName}/default.yaml;

      age = {
        keyFile = lib.mkDefault "/var/lib/sops-nix/key.txt";
        sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];
      };
    };
  };
}
