{
  self,
  config,
  lib,
  osConfig ? null,
  ...
}:

let
  cfg = config.dotnix.security.sshIdentityKeysMount;

  osCfg = if osConfig == null then { } else osConfig;

  hostName = lib.attrByPath [ "networking" "hostName" ] null osCfg;

  systemSshKeysMountCfg = lib.attrByPath [ "dotnix" "security" "sshKeysMount" ] {
    enable = false;
    identityKeys = { };
  } osCfg;

  systemIdentityKeys =
    if systemSshKeysMountCfg.enable then
      builtins.attrValues systemSshKeysMountCfg.identityKeys
    else
      [ ];

  systemManages =
    keyType:
    lib.any (value: value.userName == config.home.username && value.${keyType}) systemIdentityKeys;

  conflictEd25519 = cfg.ed25519 && systemManages "ed25519";
  conflictRsa = cfg.rsa && systemManages "rsa";
  conflictKeyTypes = (lib.optional conflictEd25519 "ed25519") ++ (lib.optional conflictRsa "rsa");

  mkSopsEntry =
    {
      secretName,
      secretKey,
      path,
      mode,
    }:
    {
      ${secretName} = {
        sopsFile = cfg.secretFile;
        key = secretKey;

        inherit path mode;
      };
    };
in
{
  options.dotnix.security.sshIdentityKeysMount = {
    enable = lib.mkEnableOption "Automatic mounting of SSH identity keys from sops secrets for the current Home Manager user.";

    secretFile = lib.mkOption {
      type = lib.types.path;
      default = self + /secrets/personal/${config.home.username}/default.yaml;
      description = "Path to the personal secret file for this Home Manager user.";
    };

    identityName = lib.mkOption {
      type = lib.types.str;
      default = if hostName == null then config.home.username else "${config.home.username}@${hostName}";
      description = "Identity key set name used under ssh_id_*_keys in the secret file.";
    };

    ed25519SecretKey = lib.mkOption {
      type = lib.types.str;
      default = "ssh_id_ed25519_keys/${cfg.identityName}";
    };

    rsaSecretKey = lib.mkOption {
      type = lib.types.str;
      default = "ssh_id_rsa_keys/${cfg.identityName}";
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

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = conflictKeyTypes == [ ];
        message = "dotnix.security.sshIdentityKeysMount conflicts with dotnix.security.sshKeysMount for user '${config.home.username}' (${lib.concatStringsSep ", " conflictKeyTypes}). Disable one side for the overlapping key types.";
      }
    ];

    sops.secrets =
      (lib.optionalAttrs cfg.ed25519 (
        (mkSopsEntry {
          secretName = "ssh_id_ed25519_key";
          secretKey = "${cfg.ed25519SecretKey}/private";

          path = "${config.home.homeDirectory}/.ssh/id_ed25519";
          mode = "0600";
        })

        // (mkSopsEntry {
          secretName = "ssh_id_ed25519_key.pub";
          secretKey = "${cfg.ed25519SecretKey}/public";

          path = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
          mode = "0644";
        })
      ))

      // (lib.optionalAttrs cfg.rsa (
        (mkSopsEntry {
          secretName = "ssh_id_rsa_key";
          secretKey = "${cfg.rsaSecretKey}/private";

          path = "${config.home.homeDirectory}/.ssh/id_rsa";
          mode = "0600";
        })

        // (mkSopsEntry {
          secretName = "ssh_id_rsa_key.pub";
          secretKey = "${cfg.rsaSecretKey}/public";

          path = "${config.home.homeDirectory}/.ssh/id_rsa.pub";
          mode = "0644";
        })
      ));
  };
}
