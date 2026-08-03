{
  self,
  config,
  pkgs,
  ...
}:

{
  users.mutableUsers = false;

  users.users = {
    root = {
      hashedPasswordFile = config.sops.secrets.hashed_user_password_root.path;

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1VYnTNTHyO/UFEDulmINIKe8UOy0pFFHWGXbe9w479 suu@mochi"
      ];
    };

    suu = {
      isNormalUser = true;
      description = "Xin Su";

      extraGroups = with config.users.groups; [
        wheel.name
        trusted.name
      ];

      hashedPasswordFile = config.sops.secrets.hashed_user_password_suu.path;

      shell = pkgs.fish;

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1VYnTNTHyO/UFEDulmINIKe8UOy0pFFHWGXbe9w479 suu@mochi"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7KXjvl2CYXIwSSwWuKdEATVKuUTamUGrHCqdaqsDuy suu@taco"
      ];
    };
  };

  home-manager.users =
    let
      byUserHost = id: self + "/nixos/home/${id}/home.nix";
    in
    {
      suu = byUserHost "suu@mochi";
    };

  sops.secrets = {
    hashed_user_password_root = {
      key = "hashed_user_passwords/root";
      neededForUsers = true;
    };

    hashed_user_password_suu = {
      key = "hashed_user_passwords/suu";
      neededForUsers = true;
    };
  };
}
