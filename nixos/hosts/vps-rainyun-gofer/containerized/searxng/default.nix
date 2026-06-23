{ self, config, ... }:

{
  sops.secrets.searxng_env = {
    sopsFile = self + /secrets/nixos/${config.networking.hostName}/searxng.yaml;
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) pods volumes;
    in
    {
      pods = {
        searxng = {
          podConfig = {
            name = "searxng";

            publishPorts = [
              "8082:8080"
            ];
          };
        };
      };

      containers = {
        searxng-core = {
          containerConfig = {
            pod = pods.searxng.ref;
            name = "searxng-core";
            image = "docker.io/searxng/searxng:latest";

            volumes = [
              "${./config}:/etc/searxng/:ro"
              "${volumes.searxng-core-data.ref}:/var/cache/searxng/"
            ];

            environments = {
              SEARXNG_BIND_ADDRESS = "localhost";
              SEARXNG_PORT = "8080";
              SEARXNG_BASE_URL = "https://search.ouoi.ch";
              SEARXNG_VALKEY_URL = "valkey://localhost:6379/0";
            };

            environmentFiles = [ config.sops.secrets.searxng_env.path ];
          };
        };

        searxng-valkey = {
          containerConfig = {
            pod = pods.searxng.ref;
            name = "searxng-valkey";
            image = "docker.io/valkey/valkey:9-alpine";

            exec = "valkey-server --save 30 1 --loglevel warning";

            volumes = [
              "${volumes.searxng-valkey-data.ref}:/data/"
            ];
          };
        };
      };

      volumes = {
        searxng-core-data = {
          volumeConfig = {
            name = "searxng-core-data";
          };
        };

        searxng-valkey-data = {
          volumeConfig = {
            name = "searxng-valkey-data";
          };
        };
      };
    };
}
