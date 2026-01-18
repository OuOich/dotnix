{
  self,
  config,
  pkgs,
  ...
}:

{
  users.users = {
    root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCfZ2IPPTxJz+hBod0mwsLfIBlBgeam87+LPQqN/DfD cheng@mochi"
      ];
    };

    cheng = {
      description = "ChengCheng_0v0";

      isNormalUser = true;
      extraGroups = with config.users.groups; [
        wheel.name
        trusted.name
      ];

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
