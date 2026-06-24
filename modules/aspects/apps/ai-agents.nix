{ den, pkgs, lib, config, inputs, ... }:

#change flake output to https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup
#provides in microvm; see https://michael.stapelberg.ch/posts/2026-02-01-coding-agent-microvm-nix/
let
  aiConfig = {
    dataDir = "/data/ai_models";
    ollamaHost = "127.0.0.1";
    ollamaPort = 11434;
  };

  ollamaModels = [ "gemma4:e4b" "qwen3.6:27b" "nomic-embed-text" ];

in
{
  flake-file.inputs = {
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
    };
  };

  den.aspects.AI = {
    includes = [
      den.aspects.hermes
      den.provides.obsidian
    ];
  };

  den.aspects.hermes = {
    includes = [den.aspects.sops];

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
    homeManager = { pkgs, config, lib, ... }: {
      home.packages = with pkgs; [ ollama ];

      launchd.agents.ollama = {
        enable = true;
        config = {
          ProgramArguments = [ "${pkgs.ollama}/bin/ollama" "serve" ];
          EnvironmentVariables = {
            OLLAMA_KEEP_ALIVE = "0";
            OLLAMA_MODELS = aiConfig.dataDir + "/ollama";
            OLLAMA_HOST = "${aiConfig.ollamaHost}:${toString aiConfig.ollamaPort}";
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

  #Not done config
  den.provides.avanonyme_agent = {
    #obsidian should come here when this is ready
    #includes = [den.provides.obsidian];
    nixos.services.hermes-agent ={
      #for platforms requiring oauth
      authFile = config.sops.secrets."hermes/auth.json".path;

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
      extraPlugins = {};
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
