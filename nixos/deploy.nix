{ self, inputs, ... }:

{
  nodes = {
    mochi = {
      hostname = "192.168.122.9";
      sshUser = "root";

      sshOpts = [
        "-o"
        "ConnectTimeout=60"
        "-o"
        "ServerAliveInterval=30"
        "-o"
        "ServerAliveCountMax=5"
      ];

      fastConnection = true;
      activationTimeout = 1200;
      confirmTimeout = 1200;

      profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.mochi;
    };

    taco = {
      hostname = "192.168.2.5";
      sshUser = "root";

      sshOpts = [
        "-o"
        "ConnectTimeout=60"
        "-o"
        "ServerAliveInterval=30"
        "-o"
        "ServerAliveCountMax=5"
      ];

      fastConnection = true;
      activationTimeout = 1200;
      confirmTimeout = 1200;

      profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.taco;
    };

    vps-rainyun-gofer = {
      hostname = "vps-rainyun-gofer.moe.cash";
      sshUser = "root";

      sshOpts = [
        "-o"
        "ConnectTimeout=60"
        "-o"
        "ServerAliveInterval=30"
        "-o"
        "ServerAliveCountMax=5"
      ];

      fastConnection = true;
      activationTimeout = 1200;
      confirmTimeout = 1200;

      profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.vps-rainyun-gofer;
    };
  };
}
