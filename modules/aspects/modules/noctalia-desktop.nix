{den, inputs, ...}:
{
  flake-file.inputs.noctalia= {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.noctalia-desktop = {
    includes = [
      den.aspects.niri
      den.aspects.niri._.niri_settings_1

      ];

    nixos = { host, pkgs, ... }: {
      imports = [ inputs.noctalia.nixosModules.default ];

      # Additional packages that complement Noctalia
      environment.systemPackages = with pkgs; [
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
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
