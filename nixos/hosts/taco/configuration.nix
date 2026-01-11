{ pkgs, ... }:

{
  networking.hostName = "taco";

  dotnix.templates.generalDesktop.enable = true;

  dotnix.configurations = {
    qemuGuest.enable = true;
  };

  imports = [
    ./hardware-configuration.nix
  ];

  time.timeZone = "Asia/Shanghai";

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDK2uKnIK1KU3FSnHKplbTxxxqOOGdJg3/pqGow1CUUO chengcheng_0v0@Cheng-NixOS-PC"
  ];

  system.stateVersion = "25.11";
}
