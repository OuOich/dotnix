{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.loader.grub.enable = lib.mkDefault true;

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";

        content = {
          type = "gpt";

          partitions = {
            boot = {
              type = "EF02";
              size = "1M";
            };

            swap = {
              size = "4G";
              content = {
                type = "swap";
                discardPolicy = "both";
              };
            };

            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
