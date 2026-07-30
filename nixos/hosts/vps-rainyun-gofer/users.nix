{ config, ... }:

{
  # services.getty.autologinUser = config.users.users.root.name;

  users.mutableUsers = false;

  users.users = {
    root = {
      hashedPasswordFile = config.sops.secrets.hashed_user_password_root.path;

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDK2uKnIK1KU3FSnHKplbTxxxqOOGdJg3/pqGow1CUUO suu@taco"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCfZ2IPPTxJz+hBod0mwsLfIBlBgeam87+LPQqN/DfD suu@mochi"
      ];
    };

    suu = {
      isNormalUser = true;
      description = "suu";

      extraGroups = with config.users.groups; [
        wheel.name
        trusted.name
        # config.services.hermes-agent.group
      ];

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDK2uKnIK1KU3FSnHKplbTxxxqOOGdJg3/pqGow1CUUO suu@taco"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCfZ2IPPTxJz+hBod0mwsLfIBlBgeam87+LPQqN/DfD suu@mochi"
      ];
    };
  };

  sops.secrets = {
    hashed_user_password_root = {
      key = "hashed_user_passwords/root";
      neededForUsers = true;
    };
  };
}
