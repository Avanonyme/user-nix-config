# ═══════════════════════════════════════════════════════════════════════════
# NIRI WINDOW MANAGER MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Niri scrolling compositor with NVIDIA support and modern Wayland features
# 
# Source: https://github.com/sodiboo/niri-flake

{inputs, den, ...}:
{
  flake-file.inputs = {
    niri = {
    url = "github:sodiboo/niri-flake";
    inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.niri = {
    nixos = { host, pkgs, lib, config, ...}: {
      imports = [inputs.niri.nixosModules.niri];

      programs.niri = {
        enable = true;
        #Disable test to avoid "too many open files" error during Nix build
        package =
          inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-stable.overrideAttrs (_: {
              doCheck = false;
          });
      };
      #to prevent black screen
      services.displayManager.sessionPackages = [
        inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-stable
      ];
      services.displayManager.gdm = {
        enable = true;
        wayland = true;
      }; 
      #XDG desktop Portal
      xdg.portal = {
   	    enable = true;
        config.niri."org.freedesktop.impl.portal.FileChooser" = "nautilus";
    	  extraPortals = with pkgs; [
      		xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
   	    ];
        configPackages = with pkgs; [
      		xdg-desktop-portal-gtk
      		xdg-desktop-portal-gnome
    	  ];
      };

      environment.variables = lib.mkIf (config.hardware.nvidia.modesetting.enable or false) {
        LIBVA_DRIVER_NAME = "nvidia";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        NVD_BACKEND = "direct";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
      };

      # Essential utilities
      environment.systemPackages = with pkgs; [
        wl-clipboard
        cliphist
        grim
        slurp
        xwayland-satellite
        ghostty #terminal
        swww
        fuzzel #app launcher
      ];

    };

    homeManager = {lib, pkgs, user, ... }: {
      #imports = [ inputs.niri.homeModules.niri ];
      #home.file.".config/niri/config.kdl".source = ./config.kdl;
      programs.niri = {
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
          # Misc
          prefer-no-csd = true;
          screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png";	
          spawn-at-startup = [
            {
            #argv = ["swww-daemon"]; #why not noctalia-shell?
            command = [ "noctalia-shell"];
            }
          ];
	            # Keybindings
          binds = let
            mod = "Mod";
          in {
            ## Noctalia setup
            "${mod}+Return".action.spawn = [ "ghostty" ];
            "${mod}+Space".action.spawn-sh = "noctalia-shell ipc call launcher toggle";
            "${mod}+C".action.spawn-sh = "noctalia-shell ipc call controlCenter toggle";
            "${mod}+E".action.spawn-sh = "noctalia-shell ipc call settings toggle";
            "${mod}+N".action.spawn = [ "nautilus" ];

            /*# Audio & Brightness #KDL format
            XF86AudioRaiseVolume { spawn "qs" "-c" "noctalia-shell" "ipc" "call" "volume" "increase"; }
            XF86AudioLowerVolume { spawn "qs" "-c" "noctalia-shell" "ipc" "call" "volume" "decrease"; }
            XF86AudioMute { spawn "qs" "-c" "noctalia-shell" "ipc" "call" "volume" "muteOutput"; }
            XF86MonBrightnessUp { spawn "qs" "-c" "noctalia-shell" "ipc" "call" "brightness" "increase"; }
            XF86MonBrightnessDown { spawn "qs" "-c" "noctalia-shell" "ipc" "call" "brightness" "decrease"; }
             */       

            ## Window management 
            "${mod}+Q".action.close-window = {};
            "${mod}+Shift+Q".action.quit = {};
            "${mod}+Shift+Slash".action.show-hotkey-overlay = {};
            
            # Focus
            "${mod}+W".action.focus-window-up = {};
            "${mod}+A".action.focus-column-left = {};
            "${mod}+S".action.focus-window-down = {};
            "${mod}+D".action.focus-column-right = {};
            
            # Move
            "${mod}+Shift+W".action.move-window-up = {};
            "${mod}+Shift+A".action.move-column-left = {};
            "${mod}+Shift+S".action.move-window-down = {};
            "${mod}+Shift+D".action.move-column-right = {};
            
            # Workspace
            "${mod}+1".action.focus-workspace = 1;
            "${mod}+2".action.focus-workspace = 2;
            "${mod}+3".action.focus-workspace = 3;
            "${mod}+4".action.focus-workspace = 4;
            "${mod}+5".action.focus-workspace = 5;
            "${mod}+6".action.focus-workspace = 6;
            "${mod}+7".action.focus-workspace = 7;
            "${mod}+8".action.focus-workspace = 8;
            "${mod}+9".action.focus-workspace = 9;
            
            # Move to workspace
            "${mod}+Shift+1".action.move-column-to-workspace = 1;
            "${mod}+Shift+2".action.move-column-to-workspace = 2;
            "${mod}+Shift+3".action.move-column-to-workspace = 3;
            "${mod}+Shift+4".action.move-column-to-workspace = 4;
            "${mod}+Shift+5".action.move-column-to-workspace = 5;
            "${mod}+Shift+6".action.move-column-to-workspace = 6;
            "${mod}+Shift+7".action.move-column-to-workspace = 7;
            "${mod}+Shift+8".action.move-column-to-workspace = 8;
            "${mod}+Shift+9".action.move-column-to-workspace = 9;
            
            # Layout
            "${mod}+F".action.maximize-column = {};
            "${mod}+Shift+F".action.fullscreen-window = {};
            "${mod}+V".action.toggle-window-floating = {};
            "${mod}+Minus".action.set-column-width = "-10%";
            "${mod}+Equal".action.set-column-width = "+10%";
            "${mod}+Shift+Minus".action.set-window-width = "-10%";
            "${mod}+Shift+Equal".action.set-window-width = "+10%";
            
            # Screenshot
            "Print".action.screenshot = {};
            "Shift+Print".action.screenshot-screen = {};
            "${mod}+Print".action.screenshot-window = {};
          };

          # Animations
          animations = {
            enable = true;
            "window-open" = {
              "duration-ms" = 1000;
              "custom-shader" = ''
                float hash(vec2 p) {
                    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
                }

                float noise(vec2 p) {
                    vec2 i = floor(p);
                    vec2 f = fract(p);
                    f = f * f * (3.0 - 2.0 * f);
                    float a = hash(i);
                    float b = hash(i + vec2(1.0, 0.0));
                    float c = hash(i + vec2(0.0, 1.0));
                    float d = hash(i + vec2(1.0, 1.0));
                    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
                }

                float fbm(vec2 p) {
                    float v = 0.0;
                    float amp = 0.5;
                    for (int i = 0; i < 6; i++) {
                        v += amp * noise(p);
                        p *= 2.0;
                        amp *= 0.5;
                    }
                    return v;
                }

                float warpedFbm(vec2 p, float t) {
                    vec2 q = vec2(fbm(p + vec2(0.0, 0.0)),
                                  fbm(p + vec2(5.2, 1.3)));

                    vec2 r = vec2(fbm(p + 6.0 * q + vec2(1.7, 9.2) + 0.25 * t),
                                  fbm(p + 6.0 * q + vec2(8.3, 2.8) + 0.22 * t));

                    vec2 s = vec2(fbm(p + 5.0 * r + vec2(3.1, 7.4) + 0.18 * t),
                                  fbm(p + 5.0 * r + vec2(6.7, 0.9) + 0.2 * t));

                    return fbm(p + 6.0 * s);
                }

                vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                    float p = niri_clamped_progress;
                    vec2 uv = coords_geo.xy;
                    float seed = niri_random_seed * 100.0;

                    float t = p * 12.0 + seed;

                    float fluid = warpedFbm(uv * 2.0 + seed, t);

                    vec2 center = uv - 0.5;
                    float dist = length(center * vec2(1.0, 0.7));

                    float appear = (1.0 - dist * 1.2) + (1.0 - fluid) * 0.7;
                    float reveal = smoothstep(appear + 0.5, appear - 0.5, (1.0 - p) * 1.8);

                    float distort_strength = (1.0 - p) * (1.0 - p) * 0.35;
                    vec2 wq = vec2(fbm(uv * 2.0 + vec2(0.0, t * 0.2)),
                                  fbm(uv * 2.0 + vec2(5.2, t * 0.2)));
                    vec2 wr = vec2(fbm(uv * 2.0 + 4.0 * wq + vec2(1.7, 9.2)),
                                  fbm(uv * 2.0 + 4.0 * wq + vec2(8.3, 2.8)));
                    vec2 warped_uv = uv + (wr - 0.5) * distort_strength;

                    vec3 tex_coords = niri_geo_to_tex * vec3(warped_uv, 1.0);
                    vec4 color = texture2D(niri_tex, tex_coords.st);

                    return color * reveal;
                }
              '';
            };

            "window-close" = {
              "duration-ms" = 1000;
              "custom-shader" = ''
                float hash(vec2 p) {
                    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
                }

                float noise(vec2 p) {
                    vec2 i = floor(p);
                    vec2 f = fract(p);
                    f = f * f * (3.0 - 2.0 * f);
                    float a = hash(i);
                    float b = hash(i + vec2(1.0, 0.0));
                    float c = hash(i + vec2(0.0, 1.0));
                    float d = hash(i + vec2(1.0, 1.0));
                    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
                }

                float fbm(vec2 p) {
                    float v = 0.0;
                    float amp = 0.5;
                    for (int i = 0; i < 6; i++) {
                        v += amp * noise(p);
                        p *= 2.0;
                        amp *= 0.5;
                    }
                    return v;
                }

                float warpedFbm(vec2 p, float t) {
                    vec2 q = vec2(fbm(p + vec2(0.0, 0.0)),
                                  fbm(p + vec2(5.2, 1.3)));

                    vec2 r = vec2(fbm(p + 6.0 * q + vec2(1.7, 9.2) + 0.25 * t),
                                  fbm(p + 6.0 * q + vec2(8.3, 2.8) + 0.22 * t));

                    vec2 s = vec2(fbm(p + 5.0 * r + vec2(3.1, 7.4) + 0.18 * t),
                                  fbm(p + 5.0 * r + vec2(6.7, 0.9) + 0.2 * t));

                    return fbm(p + 6.0 * s);
                }

                vec4 close_color(vec3 coords_geo, vec3 size_geo) {
                    float p = niri_clamped_progress;
                    vec2 uv = coords_geo.xy;
                    float seed = niri_random_seed * 100.0;

                    float t = p * 12.0 + seed;

                    float fluid = warpedFbm(uv * 2.0 + seed, t);

                    vec2 center = uv - 0.5;
                    float dist = length(center * vec2(1.0, 0.7));

                    float dissolve = (1.0 - dist) * 1.2 + fluid * 0.7;
                    float remain = smoothstep(dissolve + 0.5, dissolve - 0.5, p * 1.8);

                    float distort_strength = p * p * 0.4;
                    vec2 wq = vec2(fbm(uv * 2.0 + vec2(0.0, t * 0.2)),
                                  fbm(uv * 2.0 + vec2(5.2, t * 0.2)));
                    vec2 wr = vec2(fbm(uv * 2.0 + 4.0 * wq + vec2(1.7, 9.2)),
                                  fbm(uv * 2.0 + 4.0 * wq + vec2(8.3, 2.8)));
                    vec2 warped_uv = uv + (wr - 0.5) * distort_strength;

                    vec3 tex_coords = niri_geo_to_tex * vec3(warped_uv, 1.0);
                    vec4 color = texture2D(niri_tex, tex_coords.st);

                    float tail = smoothstep(1.0, 0.8, p);
                    return color * remain * tail;
                }
              '';
            };
          };

        };

      };
      
    };

  };

}
  
