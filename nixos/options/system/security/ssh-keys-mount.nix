{
  dotnix,
  config,
  lib,
  ...
}:

let
  cfg = config.dotnix.security.sshKeysMount;

  mkSopsEntry =
    {
      secretName,
      secretFile,
      secretKey,
      path,
      owner,
      group ? config.users.users.${owner}.group,
      mode,
      restartUnits ? [ ],
    }:
    {
      ${secretName} = {
        sopsFile = secretFile;
        key = secretKey;

        inherit
          path
          owner
          group
          mode
          restartUnits
          ;
      };
    };

in
{
  options.dotnix.security.sshKeysMount = {
    enable = lib.mkEnableOption "Automatic mounting of SSH keys from sops secrets.";

    hostSecretFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../../secrets/nixos/${config.networking.hostName}/default.yaml;
      description = "Path to the host-specific secret file.";
    };

    hostKeys = {
      ed25519 = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      rsa = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };

    identityKeys = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              secretFile = lib.mkOption {
                type = lib.types.path;
                default = ../../../../secrets/nixos/default.yaml;
              };
              ed25519SecretKey = lib.mkOption {
                type = lib.types.str;
                default = "ssh_id_ed25519_keys/${name}";
              };
              rsaSecretKey = lib.mkOption {
                type = lib.types.str;
                default = "ssh_id_rsa_keys/${name}";
              };

              userName = lib.mkOption {
                type = lib.types.str;
                default = (dotnix.lib.utils.parseUserHost name).userName;
                description = "The local user who owns these keys.";
              };

              ed25519 = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
              rsa = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
            };
          }
        )
      );
      default = { };
      description = "User identity keys to mount.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets =
      (lib.optionalAttrs cfg.hostKeys.ed25519 (
        (mkSopsEntry {
          secretName = "ssh_host_ed25519_key";
          secretFile = cfg.hostSecretFile;
          secretKey = "ssh_host_ed25519_key/private";

          path = "/etc/ssh/ssh_host_ed25519_key";

          owner = config.users.users.root.name;
          mode = "0600";

          restartUnits = [ config.systemd.services.sshd.name ];
        })

        // (mkSopsEntry {
          secretName = "ssh_host_ed25519_key.pub";
          secretFile = cfg.hostSecretFile;
          secretKey = "ssh_host_ed25519_key/public";

          path = "/etc/ssh/ssh_host_ed25519_key.pub";

          owner = config.users.users.root.name;
          mode = "0644";

          restartUnits = [ config.systemd.services.sshd.name ];
        })
      ))

      // (lib.optionalAttrs cfg.hostKeys.rsa (
        (mkSopsEntry {
          secretName = "ssh_host_rsa_key";
          secretFile = cfg.hostSecretFile;
          secretKey = "ssh_host_rsa_key/private";

          path = "/etc/ssh/ssh_host_rsa_key";

          owner = config.users.users.root.name;
          mode = "0600";

          restartUnits = [ config.systemd.services.sshd.name ];
        })

        // (mkSopsEntry {
          secretName = "ssh_host_rsa_key.pub";
          secretFile = cfg.hostSecretFile;
          secretKey = "ssh_host_rsa_key/public";

          path = "/etc/ssh/ssh_host_rsa_key.pub";

          owner = config.users.users.root.name;
          mode = "0644";

          restartUnits = [ config.systemd.services.sshd.name ];
        })
      ))

      // (lib.concatMapAttrs (
        name: value:
        let
          home = config.users.users.${value.userName}.home;
        in
        (lib.optionalAttrs value.ed25519 (
          (mkSopsEntry {
            secretName = "ssh_id_ed25519_key_${name}";
            secretFile = value.secretFile;
            secretKey = "${value.ed25519SecretKey}/private";

            path = "${home}/.ssh/id_ed25519";

            owner = value.userName;
            mode = "0600";
          })

          // (mkSopsEntry {
            secretName = "ssh_id_ed25519_key_${name}.pub";
            secretFile = value.secretFile;
            secretKey = "${value.ed25519SecretKey}/public";

            path = "${home}/.ssh/id_ed25519.pub";

            owner = value.userName;
            mode = "0644";
          })
        ))

        // (lib.optionalAttrs value.rsa (
          (mkSopsEntry {
            secretName = "ssh_id_rsa_key_${name}";
            secretFile = value.secretFile;
            secretKey = "${value.rsaSecretKey}/private";

            path = "${home}/.ssh/id_rsa";

            owner = value.userName;
            mode = "0600";
          })

          // (mkSopsEntry {
            secretName = "ssh_id_rsa_key_${name}.pub";
            secretFile = value.secretFile;
            secretKey = "${value.rsaSecretKey}/public";

            path = "${home}/.ssh/id_rsa.pub";

            owner = value.userName;
            mode = "0644";
          })
        ))
      ) cfg.identityKeys);
  };
}
