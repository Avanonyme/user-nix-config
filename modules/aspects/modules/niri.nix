# ═══════════════════════════════════════════════════════════════════════════
# NIRI WINDOW MANAGER MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Niri scrolling compositor with NVIDIA support and modern Wayland features

{inputs, den, ...}:
{
  flake-file.inputs = {
    niri = {
    url = "github:sodiboo/niri-flake";
    inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.niri = {
    nixos = { host, pkgs, ...}: {
    #    imports = [inputs.niri.nixosModules.niri];
        
    #    programs.niri.enable = true;

      # Essential utilities
      environment.systemPackages = with pkgs; [
        wl-clipboard
        cliphist
        grim
        slurp
        xwayland-satellite
    ];

    };

    homeManager = {lib, pkgs, user, ... }: {
      imports = [ inputs.niri.homeModules.niri ];
      programs.niri = {
        enable = true;
	
        settings = {
          # Input configuration
          input = {
            keyboard = {
              xkb = {
                layout = "us";
              };
            };
            touchpad = {
              tap = true;
              natural-scroll = true;
            };
            mouse = {
              accel-profile = "flat";
            };
          };

          # Layout
          layout = {
            gaps = 10;
            center-focused-column = "never";
            preset-column-widths = [
              { proportion = 1.0 / 3.0; }
              { proportion = 1.0 / 2.0; }
              { proportion = 2.0 / 3.0; }
            ];
            default-column-width = { proportion = 1.0 / 2.0; };
            focus-ring = {
              enable = true;
              width = 2;
            };
            border = {
              enable = false;
            };
          };

          # Animations
          animations = {
            enable = true;
          };

        };

      };
      
    };

  };

}
  
