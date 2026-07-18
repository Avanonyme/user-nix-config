{ den, pkgs, lib, config, inputs, ... }:

#change flake output to https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup
#provides in microvm; see https://michael.stapelberg.ch/posts/2026-02-01-coding-agent-microvm-nix/
let
  aiConfig = {
    dataDir = "/data/ai_models";
    ollamaHost = "127.0.0.1";
    # Listen address for the host ollama launchd agent. 0.0.0.0 so apple
    # containers can reach it (they see the host at the vmnet gateway IP,
    # not 127.0.0.1).
    ollamaListenHost = "0.0.0.0";
    ollamaPort = 11434;
    # Host as seen from inside apple containers (vmnet NAT gateway).
    # Verify with: container run --rm alpine ip route | head -1
    containerGatewayIP = "192.168.64.1";
  };

  # State dir for the CONTAINERIZED hermes instance.
  # FLAG: deliberately NOT ~/.hermes — no shared state with the host CLI
  # instance for now. Revisit if/when you want one brain.
  hermesContainerState = "/Users/avanonyme/.hermes-container";
  searxngConfigDir = "/Users/avanonyme/.config/searxng";
  searxngPort = 8080;

  ollamaModels = [ "gemma4:e4b" "qwen3.6:27b" "nomic-embed-text" ];

in
{
  flake-file.inputs = {
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
    };
  };

  den.aspects.apps.ai = {
    includes = [
      den.aspects.hermes
      den.provides.obsidian
      den.provides.avanonyme_agent
    ];
  };

  den.aspects.hermes = {
    includes = [den.aspects.security.sops];

    nixos = {host, user, config, ...}:{
      imports = [inputs.hermes-agent.nixosModules.default]; 
      
      # for full options see https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup

      services.hermes-agent = {
        enable = true;

        settings.model.default = "deepseek/deepseek-v4-flash";
        settings.models = {
          "deepseek/deepseek-v4-flash" = {
            provider = "deepseek";
            apiKeyEnv = "DEEPSEEK_API_KEY";
          };
          "deepseek/deepseek-v4-pro" = {
            provider = "deepseek";
            apiKeyEnv = "DEEPSEEK_API_KEY";
          };
          "deepseek/fable-5" = {
            provider = "anthropic";
            apiKeyEnv = "ANTHROPIC_API_KEY";
          };
          "ollama/qwen3.6:27b" = {
            provider = "ollama";
            baseUrl = "http://${aiConfig.ollamaHost}:${toString aiConfig.ollamaPort}/v1";
          };

          "ollama/gemma4:e4b" = {
            provider = "ollama";
            baseUrl = "http://${aiConfig.ollamaHost}:${toString aiConfig.ollamaPort}/v1";
          };
        };

        #secrets 
        environmentFiles = [  config.sops.templates."hermes.env".path];
        
        # make cli share state with gateway
        addToSystemPackages = true;

        # container options; ways to use microvm?  https://michael.stapelberg.ch/posts/2026-02-01-coding-agent-microvm-nix/
        container.enable = false;
        # also by default writes in /data which we dont want (need /data/models)

        settings = {
          terminal = { backend = "local"; timeout = 180; };
        };
      };

    };

    #ollama home config ; basic setup for local llm
    ollama-darwin = {
      homeManager = { pkgs, config, lib, ... }: {
        home.packages = with pkgs; [ ollama ];

        launchd.agents.ollama = {
          enable = true;
          config = {
            ProgramArguments = [ "${pkgs.ollama}/bin/ollama" "serve" ];
            EnvironmentVariables = {
              OLLAMA_KEEP_ALIVE = "0";
              OLLAMA_MODELS = aiConfig.dataDir + "/ollama";
              OLLAMA_HOST = "${aiConfig.ollamaListenHost}:${toString aiConfig.ollamaPort}";
            };
            RunAtLoad = true;
            KeepAlive = false;
            StandardOutPath = "/tmp/ollama.log";
            StandardErrorPath = "/tmp/ollama.err";
          };
        };

        home.activation.ollamaPull = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          for model in ${lib.concatStringsSep " " ollamaModels}; do
            $DRY_RUN_CMD ${pkgs.ollama}/bin/ollama pull "$model" 2>/dev/null || true
          done
        '';
      };
    };
  };

  # ── Containerized agent stack (macOS / apple-container) ──────────────
  # Hermes (official Docker image) + SearXNG, each in its own apple
  # container (lightweight Linux VM). Include den.aspects.hermes.container
  # on arctic. NOTE: including this evaluates the parent den.aspects.hermes,
  # so the host ollama homeManager block comes along — intended on the Mac
  # (agents talk to host ollama over the vmnet gateway).
  #
  # FLAG: hermesContainerState is deliberately separate from ~/.hermes.
  # The containerized gateway and your host CLI hermes do NOT share
  # sessions/memory/skills for now. Unify later if wanted.
  den.aspects.hermes.container = {

    includes = [ den.aspects.apple-container ];
    darwin = { ... }: {
      services.containerization = {

        containers.searxng = {
          image = "docker.io/searxng/searxng:latest";
          autoStart = true;
          volumes = [ "${searxngConfigDir}:/etc/searxng" ];
          # published so the host can use it too (http://localhost:)
          extraArgs = [ "--publish" "${toString searxngPort}:8080" ];
        };

        containers.hermes = {
          image = "docker.io/nousresearch/hermes-agent:latest";
          autoStart = true;
          init = true; # s6 /init is PID1 inside, but let the VM reap too
          volumes = [ "${hermesContainerState}:/opt/data" ];
          env = {
            # container-to-container DNS: <name>.test
            SEARXNG_URL = "http://searxng.test:${toString searxngPort}";
          };
        };
      };
    };

    homeManager = { pkgs, lib, config, ... }: {
      # SearXNG settings must be a REAL file, not an xdg.configFile symlink:
      # the bind mount exposes the symlink but not its /nix/store target
      # inside the container VM. So we install it via activation.
      # secret_key is generated once and preserved across rebuilds.
      home.activation.searxngConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p ${searxngConfigDir}
        if [ -f ${searxngConfigDir}/.secret_key ]; then
          _sxg_key=$(cat ${searxngConfigDir}/.secret_key)
        else
          _sxg_key=$(${pkgs.openssl}/bin/openssl rand -hex 32)
          echo "$_sxg_key" > ${searxngConfigDir}/.secret_key
          chmod 600 ${searxngConfigDir}/.secret_key
        fi
        cat > ${searxngConfigDir}/settings.yml <<EOF
        # Managed by home-manager (ai-agents.nix) — do not edit by hand.
        use_default_settings: true
        server:
          secret_key: "$_sxg_key"
          limiter: false        # no valkey in this deployment
          image_proxy: true
        search:
          formats:              # hermes' searxng backend needs the JSON API
            - html
            - json
        EOF
      '';

      # First-run seed of the containerized hermes config. Only written if
      # missing so hermes-managed edits (skills, plugins, etc.) persist.
      # The container reads /opt/data/config.yaml == this file.
      home.activation.hermesContainerSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p ${hermesContainerState}
        if [ ! -f ${hermesContainerState}/config.yaml ]; then
          cat > ${hermesContainerState}/config.yaml <<EOF
        model:
          default: deepseek/deepseek-v4-flash
        models:
          deepseek/deepseek-v4-flash:
            provider: deepseek
            apiKeyEnv: DEEPSEEK_API_KEY
          deepseek/deepseek-v4-pro:
            provider: deepseek
            apiKeyEnv: DEEPSEEK_API_KEY
          ollama/qwen3.6:27b:
            provider: ollama
            baseUrl: http://${aiConfig.containerGatewayIP}:${toString aiConfig.ollamaPort}/v1
          ollama/gemma4:e4b:
            provider: ollama
            baseUrl: http://${aiConfig.containerGatewayIP}:${toString aiConfig.ollamaPort}/v1
        web:
          search_backend: searxng
        terminal:
          backend: local
          timeout: 180
        EOF
        fi
        # TODO(secrets): copy the sops-rendered hermes env into place.
        # The container reads /opt/data/.env. Point this at your darwin
        # sops template path once wired, e.g.:
        #   cp /run/secrets/rendered/hermes.env ${hermesContainerState}/.env
        if [ ! -f ${hermesContainerState}/.env ]; then
          echo "# DEEPSEEK_API_KEY=..." > ${hermesContainerState}/.env
          chmod 600 ${hermesContainerState}/.env
        fi
      '';
    };
  };

  #Not done config
  den.provides.avanonyme_agent = {
    #obsidian should come here when this is ready
    #includes = [den.provides.obsidian];
    nixos.services.hermes-agent ={

      settings = {
        display = { compact = false; personality = "kawaii"; };
        memory = { memory_enabled = true; user_profile_enabled = true; };
      };
      # TODO: set up
      mcpServers = {
        filesystem = {
          command = "npx";
          args = [ "-y" "@modelcontextprotocol/server-filesystem" "/data/workspace" ];
        };
        github = {
          command = "npx";
          args = [ "-y" "@modelcontextprotocol/server-github" ];
          env.GITHUB_PERSONAL_ACCESS_TOKEN = "\${GITHUB_TOKEN}"; # resolved from .env
        };
      };
      #extraPlugins = {};
      settings.plugins.enabled = [];

      extraDependencyGroups = ["matrix"];
    };
  };
  den.provides.obsidian = {
    darwin = { ... }: { homebrew.casks = [ "obsidian" ]; };
    nixos = { pkgs, ... }: { 
      environment.systemPackages = with pkgs; [ obsidian ];
      #services.hermes-agent.documents = {
      #  "Obsidian_vault" = "";
      #  "USER.md" = "";
      #};
    };
  };
}
