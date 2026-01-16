{ self, inputs, ... }:

{
  nodes = {
    mochi = {
      hostname = "192.168.122.9";
      sshUser = "root";

      fastConnection = true;

      profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.mochi;
    };
  };
}
