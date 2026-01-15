{
  config,
  lib,
  ...
}:

let
  cfg = config.dotnix.configurations.commonSops;
in
{
  options.dotnix.configurations.commonSops = {
    enable = lib.mkEnableOption "Whether to enable the common sops-nix configuration.";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      age = {
        keyFile = lib.mkDefault "/var/lib/sops-nix/key.txt";
        sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];
      };
    };
  };
}
