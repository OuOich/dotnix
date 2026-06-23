{
  self,
  config,
  pkgs,
  lib,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    agent-browser
    chromium
  ];

  sops.secrets.hermes_env = {
    sopsFile = self + /secrets/nixos/${config.networking.hostName}/hermes.yaml;
  };

  services.hermes-agent = {
    enable = true;

    extraDependencyGroups = [ "messaging" ];

    container = {
      enable = false;
      # image = "ubuntu:24.04";
      # hostUsers = [ "cheng" ];
    };

    settings = {
      display = {
        interface = "tui";
      };

      terminal = {
        backend = "local";
        cwd = ".";
      };

      web = {
        search_backend = "searxng";
      };

      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
        write_approval = true;
        memory_char_limit = 2200;
        user_char_limit = 1375;
      };

      skills = {
        write_approval = true;
      };

      telegram = {
        reactions = false;
        require_mention = true;
        observe_unmentioned_group_messages = true;
        allowed_chats = [ ];
        group_allowed_chats = [ ];
      };

      gateway = {
        platforms = {
          telegram = {
            extra = {
              status_indicator = false;
              status_online = "🐾 Online";
              status_offline = "💤 Offline";
              notifications = "important";
            };
          };
        };
      };

      model = {
        provider = "openrouter";
        default = "deepseek/deepseek-v4-flash:nitro";
      };

      auxiliary = {
        vision = {
          provider = "openrouter";
          model = "qwen/qwen3.7-plus";
        };

        title_generation = {
          provider = "openrouter";
          model = "meta-llama/llama-3.1-8b-instruct";
        };

        approval = {
          provider = "openrouter";
          model = "meta-llama/llama-3.1-8b-instruct:nitro";
        };

        tts_audio_tags = {
          provider = "openrouter";
          model = "meta-llama/llama-3.1-8b-instruct";
        };

        web_extract = {
          provider = "openrouter";
          model = "deepseek/deepseek-v4-flash:nitro";
        };

        compression = {
          provider = "openrouter";
          model = "deepseek/deepseek-v4-flash:nitro";
        };

        skills_hub = {
          provider = "auto";
        };

        mcp = {
          provider = "auto";
        };

        triage_specifier = {
          provider = "openrouter";
          model = "deepseek/deepseek-v4-flash";
        };

        kanban_decomposer = {
          provider = "openrouter";
          model = "deepseek/deepseek-v4-flash";
        };

        profile_describer = {
          provider = "openrouter";
          model = "deepseek/deepseek-v4-flash";
        };

        curator = {
          provider = "openrouter";
          model = "deepseek/deepseek-v4-flash";
        };
      };
    };

    environment = {
      AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
      AGENT_BROWSER_PROFILE = "/var/lib/hermes/browser-profile";
      AGENT_BROWSER_ARGS = "--no-sandbox,--disable-dev-shm-usage";
      SEARXNG_URL = "http://localhost:8082";
      TELEGRAM_HOME_CHANNEL = "5796851903";
      TELEGRAM_ALLOWED_USERS = "5796851903";
    };

    environmentFiles = [ config.sops.secrets.hermes_env.path ];

    addToSystemPackages = true;
  };

  systemd.services.hermes-agent = {
    serviceConfig = {
      NoNewPrivileges = lib.mkForce false;
    };

    path = lib.mkBefore [ "/run/current-system/sw" ];

    environment = {
      AGENT_BROWSER_EXECUTABLE_PATH =
        config.services.hermes-agent.environment.AGENT_BROWSER_EXECUTABLE_PATH;
      AGENT_BROWSER_PROFILE = config.services.hermes-agent.environment.AGENT_BROWSER_PROFILE;
      AGENT_BROWSER_ARGS = config.services.hermes-agent.environment.AGENT_BROWSER_ARGS;
    };
  };

  users.users.hermes = {
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };

  environment.variables = {
    AGENT_BROWSER_EXECUTABLE_PATH =
      config.services.hermes-agent.environment.AGENT_BROWSER_EXECUTABLE_PATH;
    AGENT_BROWSER_PROFILE = config.services.hermes-agent.environment.AGENT_BROWSER_PROFILE;
    AGENT_BROWSER_ARGS = config.services.hermes-agent.environment.AGENT_BROWSER_ARGS;
  };
}
