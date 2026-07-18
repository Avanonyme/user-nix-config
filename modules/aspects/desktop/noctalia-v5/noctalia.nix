{den, inputs, ...}:
{
  flake-file.inputs.noctalia= {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.desktop.noctalia = {
    includes = with den.aspects; [
      core.sound
      security.polkit
      desktop.niri
      desktop.noctalia-greeter
      ];

    nixos = { host, pkgs, ... }: {
     # imports = [ inputs.noctalia.nixosModules.default ];

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
      
      
      programs.noctalia = {
        enable = true;
        settings = builtins.readFile ./noctalia.toml;

      };
    };
  };
}
