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
      # Declarative ~/.pi config on macOS and Linux
      xdg.configFile."pi/agent/models.json".source = ../.configs/ollama-models.json;
      xdg.configFile."pi/agent/settings.json".source = ../.configs/ollama-settings.json;
    };

    nixos = {pkgs, config,...}: {

      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        
        #default
        host = "127.0.0.1"; #could change for tailscale host
        port = 11434;

      };
    };
  };
}
