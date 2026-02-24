{
  self,
  config,
  pkgs,
  ...
}:

{
  users.users = {
    root = {
      hashedPasswordFile = config.sops.secrets.hashed_user_password_root.path;

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCfZ2IPPTxJz+hBod0mwsLfIBlBgeam87+LPQqN/DfD cheng@mochi"
      ];
    };

    cheng = {
      isNormalUser = true;
      description = "ChengCheng_0v0";

      extraGroups = with config.users.groups; [
        wheel.name
        trusted.name
      ];

      hashedPasswordFile = config.sops.secrets.hashed_user_password_cheng.path;

      shell = pkgs.fish;

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCfZ2IPPTxJz+hBod0mwsLfIBlBgeam87+LPQqN/DfD cheng@mochi"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDK2uKnIK1KU3FSnHKplbTxxxqOOGdJg3/pqGow1CUUO cheng@taco"
      ];
    };
  };

  home-manager.users =
    let
      byUserHost = id: self + "/nixos/home/${id}/home.nix";
    in
    {
      cheng = byUserHost "cheng@mochi";
    };
}
