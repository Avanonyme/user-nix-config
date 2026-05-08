{den, inputs, pkgs, ...}:
{
  # hermes-agent: pulling the per-user HM module since upstream only has a NixOS module
  # PR: https://github.com/NousResearch/hermes-agent/pull/9087 (unmerged — pinned to feature branch)
  flake-file.inputs.hermes = {
    url = "github:yzx9/hermes-agent/feat/home-manager";
  };

  # nix-darwin PR #972 (services.ollama) is unmerged — managing ollama via launchd.agents instead
  den.aspects.hermes-agent = {
    homeManager = {pkgs, ...}: {
      imports = [ inputs.hermes.homeManagerModules.default ];

      programs.hermes-agent = {
        enable = true;
        settings.model = "deepseek/deepseek-chat"; # deepseek-v4-flash public model id
      };

      # Ollama: installed as package, service managed via launchd user agent
      # Replace services.ollama (nix-darwin PR #972, still unmerged)
      home.packages = [ pkgs.ollama ];

      launchd.agents.ollama = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.ollama}/bin/ollama"
            "serve"
          ];
          EnvironmentVariables = {
            OLLAMA_KEEP_ALIVE = "0";
            OLLAMA_MODELS = "/data/ai_models/ollama";
            OLLAMA_HOST = "127.0.0.1:11434";
          };
          RunAtLoad = true;
          KeepAlive = false;
          StandardOutPath = "/tmp/ollama.log";
          StandardErrorPath = "/tmp/ollama.err";
        };
      };
    };
  };
}
