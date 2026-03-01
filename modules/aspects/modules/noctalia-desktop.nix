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

    nixos = { host, ... }: {
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
    homeManager = { user, ... }: {
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
          # Warm golden amber — solar energy, lantern light
          mPrimary = "#dab064";

          # Soft leaf green — living canopy, mid-range vegetation
          mSecondary = "#82bf79";

          # Earthy terracotta — clay, bark, warm soil
          mTertiary = "#975c3a";

          # Deep forest teal — base surface, darkest inhabited tone
          mSurface = "#254343";

          # Elevated teal — card/panel surface, one step above base
          mSurfaceVariant = "#2f4e50";

          # Warm cream — primary text, parchment in sunlight
          mOnSurface = "#fdf8d8";

          # Muted sage — secondary/subdued text
          mOnSurfaceVariant = "#abbf9c";

          # Dark teal — borders and dividers
          mOutline = "#4a6463";

          # Deepest forest dark — shadow, beneath canopy floor
          mShadow = "#233f40";

          # Deep crimson — error, still earthy but urgent
          mError = "#901e3f";

          # Cream on crimson — legible on dark error
          mOnError = "#fdf8d8";

          # Dark on lit accents
          mOnPrimary   = "#233f40";
          mOnSecondary = "#233f40";
          mOnTertiary  = "#233f40";
        };
      };
    };
  };
}
