{den, inputs, ...}:
{
  flake-file.inputs.noctalia= {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.noctalia-desktop = {
    includes = [
      den.aspects.niri
      ];

    nixos = { host, pkgs, ... }: {
      imports = [ inputs.noctalia.nixosModules.default ];

      # Enable Noctalia shell systemd service
      services.noctalia-shell = {
        enable = true;
      };

      # Additional packages that complement Noctalia
      environment.systemPackages = with pkgs; [
        brightnessctl
        playerctl
        pamixer
        libnotify
      ];
    };

    # per-user
    homeManager = { user, ... }: {
      imports = [ inputs.noctalia.homeModules.default ];
      
      
      programs.noctalia-shell = {
        enable = true;
        settings = builtins.fromJSON (builtins.readFile ./../../.config/noctalia.json);

      };
    };
  };
}
