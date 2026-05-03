{den, inputs, ...}:
{
  flake-file.inputs.nix-pi-agent = {
    url = "github:rbright/nix-pi-agent";
    inputs.nixpkgs.follows = "nixpkgs";
  };


  den.aspects.pi-agent = {
    # Per-user home-manager config (works on Linux and macOS)
    homeManager = { pkgs, user, config, ... }: 
    let
      system = pkgs.system; # "x86_64-linux" or "aarch64-darwin"
      piPkg = inputs.nix-pi-agent.packages.${system}.pi-agent;
    in 
    {
      home.packages = [
        piPkg
      ];
    };

    nixos = {pkgs, config,...}: {

      services.ollama = {
        enable = true;
        package = pkgs.ollama-vulkan;
        user = "ollama";
        group = "users";

        loadModels = [
          #"qwen3.6:35b"
          "qwen3.6:27b-coding-mxfp8"
          #"deepseek-v3:671b" #i'm afraid
        ];

        environmentVariables = {
          OLLAMA_VULKAN = "1";
          OLLAMA_KEEP_ALIVE = "0";
          OLLAMA_MODELS = "/data/ai_models/ollama";
          GGML_VK_VISIBLE_DEVICES = "0";
        };

        #default #eventually expose as tailscale/headscale app
        host = "127.0.0.1"; 
        port = 11434;
        #use both AMD and NVIDIA by choosing one backend per server

      };
    };
  };
}
