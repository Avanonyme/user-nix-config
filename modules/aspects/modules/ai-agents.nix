{ den, pkgs, lib, config, inputs, ... }:

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
    hermes = {
      url = "github:yzx9/hermes-agent/feat/home-manager";
    };
  };

  den.aspects.AI = {
    includes = [
      den.provides.hermes
      den.provides.obsidian
    ];
  };

  den.provides.hermes = {

    homeManager = { pkgs, config, lib, ... }: {
      imports = [ inputs.hermes.homeManagerModules.default ];

      programs.hermes-agent = {
        enable = true;
        settings.model = lib.mkDefault "deepseek/deepseek-v4-flash";
        settings.models = {
          "deepseek/deepseek-v4-flash" = {
            provider = "deepseek";
            apiKeyEnv = "DEEPSEEK_API_KEY";
          };
          "deepseek/deepseek-v4-pro" = {
            provider = "deepseek";
            apiKeyEnv = "DEEPSEEK_API_KEY";
          };
          "ollama/qwen3.6" = {
            provider = "ollama";
            baseUrl = "http://${aiConfig.ollamaHost}:${toString aiConfig.ollamaPort}/v1";
          };
        };
      };

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

  den.provides.obsidian = {
    darwin = { ... }: { homebrew.casks = [ "obsidian" ]; };
    homeManager = { pkgs, ... }: { 
      home.packages = with pkgs; []
       ++ lib.optionals stdenv.isLinux [ obsidian ]; 
    };
  };
}
