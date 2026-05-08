{den, inputs, ...}:
{
  flake-file.inputs.hermes = {
    # pulling the per user config cause the default is only a nixos module
    url = "github:yzx9/hermes-agent/feat/home-manager";
  };


  den.aspects.hermes-agent = {
    home-manager = {
      services.ollama = {
        enable = true;
        loadModels = [
          "qwen3.6"
          "all-minilm"
        ];

        environmentVariables = {
          OLLAMA_KEEP_ALIVE = "0";
          OLLAMA_MODELS = "/data/ai_models/ollama";
        };

        #default #eventually expose as tailscale/headscale app
        host = "127.0.0.1"; 
        port = 11434;
      };
      programs.hermes-agent = {
        enable = true; 
        settings.model = "DeepSeek/deepseek-v4-flash";
      };

    };
  };
}
