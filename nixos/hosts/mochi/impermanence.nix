let
  persistenceMountPoint = "/persist";
in
{
  dotnix.impermanence = {
    enable = true;
    inherit persistenceMountPoint;
  };

  # Mount the persisted age key directory before stage-2 activation.
  fileSystems."/var/lib/sops-nix" = {
    device = "${persistenceMountPoint}/var/lib/sops-nix";
    fsType = "none";
    options = [
      "bind"
      "x-gvfs-hide"
    ];
    neededForBoot = true;
    depends = [ persistenceMountPoint ];
  };

  environment.persistence.${persistenceMountPoint} = {
    hideMounts = true;

    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"

      "/etc/NetworkManager/system-connections"

      {
        directory = "/var/lib/sops-nix";
        mode = "0700";
      }

      {
        directory = "/root";
        mode = "0700";
      }
    ];

    files = [
      "/etc/machine-id"
    ];
  };
}
