{den, inputs, ...}:
{
  flake-file.inputs.noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.noctalia-desktop = {
    includes = [
      den.aspects.niri
      den.aspects.zen-browser
      ];

    nixos = { pkgs, ... }: {
      imports = [ inputs.noctalia-shell.nixosModules.default ];

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
    homeManager = { pkgs, ... }: {
      imports = [ inputs.noctalia-shell.homeModules.default ];
            
      # Enable Noctalia shell user configuration
      programs.noctalia-shell = {
        enable = true;

        # Shell settings
        settings = {
          bar = {
            position = "bottom";
            floating = true;
            backgroundOpacity = 0.95;
          };
          general = {
            animationSpeed = 1.5;
            radiusRatio = 1.2;
          };
          colorSchemes = {
            darkMode = true;
            useWallpaperColors = true;
          };
        };

        # Color configuration (Catppuccin Mocha inspired)
        colors = {
          # Warm amber — lantern light, solar energy, sunlight through canopy
          mPrimary = "#a5bd0b";

          # Vivid leaf green — living vegetation, growing things
          mSecondary = "#58b040";

          # Terracotta sunset coral — clay architecture, warm dusk sky
          mTertiary = "#925016";

          # Deep forest night — base surface, replaces cold blue-black
          mSurface = "#0d1a0f";

          # Forest understory — elevated/card surfaces
          mSurfaceVariant = "#182c1c";

          # Warm parchment text — replaces cold lavender
          mOnSurface = "#ddd4b0";

          # Muted canopy light — subdued/secondary text
          mOnSurfaceVariant = "#8aaa78";

          # Forest edge — borders and dividers, replaces cold grey
          mOutline = "#2c4230";

          # Shadow under canopy — deeper than surface
          mShadow = "#050d06";

          # Brick red — still readable as error but earthier than neon pink
          mError = "#ab3629";

          # All "on-X" reuse mSurface — dark text on lit accent backgrounds
          mOnError = "#0d1a0f";
          mOnPrimary = "#0d1a0f";
          mOnSecondary = "#0d1a0f";
          mOnTertiary = "#0d1a0f";
        };
      };
    };
  };
}
