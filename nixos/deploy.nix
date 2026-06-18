{ self, inputs, ... }:

{
  nodes = {
    mochi = {
      hostname = "192.168.122.9";
      sshUser = "root";

      fastConnection = true;

      profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.mochi;
    };

    taco = {
      hostname = "192.168.2.5";
      sshUser = "root";

      fastConnection = true;

      profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.taco;
    };

    vps-rainyun-gofer = {
      hostname = "vps-rainyun-gofer.moe.cash";
      sshUser = "root";

      fastConnection = true;

      profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.vps-rainyun-gofer;
    };
  };
}
