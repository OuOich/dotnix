{ config, ... }:

{
  # services.getty.autologinUser = config.users.users.root.name;

  users.mutableUsers = false;

  users.users = {
    root = {
      hashedPasswordFile = config.sops.secrets.hashed_user_password_root.path;

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1VYnTNTHyO/UFEDulmINIKe8UOy0pFFHWGXbe9w479 suu@mochi"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7KXjvl2CYXIwSSwWuKdEATVKuUTamUGrHCqdaqsDuy suu@taco"
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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1VYnTNTHyO/UFEDulmINIKe8UOy0pFFHWGXbe9w479 suu@mochi"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7KXjvl2CYXIwSSwWuKdEATVKuUTamUGrHCqdaqsDuy suu@taco"
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
