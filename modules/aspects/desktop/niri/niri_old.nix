# Niri scrolling compositor modern Wayland features
# 
# Source: https://github.com/sodiboo/niri-flake

{inputs, den, ...}:
{
  flake-file.inputs = {
    niri = {
      url = "github:sodiboo/niri-flake/very-refactor";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.desktop.niri_old = {

    nixos = { host, pkgs, lib, config, ...}: {
      imports = [inputs.niri.nixosModules.niri];

      programs.niri = {
        enable = true;
        #Disable test to avoid "too many open files" error during Nix build
        package =
          inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable.overrideAttrs (_: {
              doCheck = false;
          });
      };

      #to prevent black screen
      services.displayManager.sessionPackages = [
        inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable
      ];

      services.displayManager.gdm = {
        enable = true;
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

      #nvidia compatibility
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
        fuzzel #app launcher

        mako # notification daemon
      ];

    };

    homeManager = {lib, pkgs, user, ... }: {
      #imports = [ inputs.niri.homeModules.niri ];
      #home.file.".config/niri/config.kdl".source = ./../../.config/config.kdl;
      #programs.niri.cnnfig = ./../../.config/config.kdl;
      #https://github.com/sodiboo/niri-flake/blob/main/docs.md#programsnirisettings

      #only nixos 
      programs.niri.settings = {
        #includes = lib.mkAfter [
        #  (../../.config/blur.kdl)
        #];
        binds = 
          let
            mod = "Mod";
          in {
          ## Noctalia setup
          "${mod}+L".action.spawn = "blurred-locker";
          "${mod}+Shift+P".action.power-off-monitors= {};
          "${mod}+Return".action.spawn = [ "ghostty" ];
          "${mod}+Space".action.spawn-sh = "noctalia msg panel-toggle launcher";
          "${mod}+C".action.spawn-sh = "noctalia msg panel-toggle control-center";
          "${mod}+E".action.spawn-sh = "noctalia msg settings-toggle";
          "${mod}+N".action.spawn = [ "nautilus" ];
          "${mod}+O".action.toggle-overview = {}; 


          "XF86AudioRaiseVolume".action.spawn-sh = "noctalia msg volume-up";
          "XF86AudioLowerVolume".action.spawn-sh = "noctalia msg volume-down";
          "XF86AudioMute".action.spawn-sh = "noctalia msg volume-mute";

          "XF86AudioPlay".action.spawn-sh = "playerctl play-pause";
          "XF86AudioPause".action.spawn-sh = "playerctl play-pause";
          "XF86AudioStop".action.spawn-sh = "playerctl stop";
          "XF86AudioPrev".action.spawn-sh = "playerctl previous";
          "XF86AudioNext".action.spawn-sh = "playerctl next";

          "XF86MonBrightnessUp".action.spawn-sh = "noctalia msg brightness-up";
          "XF86MonBrightnessDown".action.spawn-sh = "noctalia msg brightness-down";



          

          ## Window management 
          "${mod}+Q".action.close-window = {};
          "${mod}+Shift+Q".action.quit = {};
          "${mod}+Shift+Slash".action.show-hotkey-overlay = {};
          
          # Focus
          "${mod}+W".action.focus-window-or-workspace-up = {};
          "${mod}+A".action.focus-column-left = {};
          "${mod}+S".action.focus-window-or-workspace-down = {};
          "${mod}+D".action.focus-column-right = {};
          
          # Move
          "${mod}+Shift+W".action.move-window-up-or-to-workspace-up = {};
          "${mod}+Shift+A".action.move-column-left = {};
          "${mod}+Shift+S".action.move-window-down-or-to-workspace-down = {};
          "${mod}+Shift+D".action.move-column-right = {};

          #Move to column
          "${mod}+BracketLeft".action.consume-or-expel-window-left = {};
          "${mod}+BracketRight".action.consume-or-expel-window-right = {};
          "${mod}+Comma".action.consume-window-into-column = {};
          "${mod}+Period".action.expel-window-from-column = {};

          
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
          "${mod}+Shift+Minus".action.set-window-height = "-10%";
          "${mod}+Shift+Equal".action.set-window-height = "+10%";
          "${mod}+M".action.maximize-window-to-edges = {};
          
          # Screenshot
          "Print".action.screenshot = {};
          "Shift+Print".action.screenshot-screen = {};
          "${mod}+Print".action.screenshot-window = {};

          #MouseWheel
          "${mod}+WheelScrollDown".action.focus-workspace-down = { };#add cooldown-ms = 150
          "${mod}+WheelScrollUp".action.focus-workspace-up = {};
          "${mod}+Ctrl+WheelScrollDown".action.move-column-to-workspace-down= {};
          "${mod}+Ctrl+WheelScrollUp".action.move-column-to-workspace-up = {};

          "${mod}+WheelScrollRight".action.focus-column-right = {};#add cooldown-ms = 150
          "${mod}+WheelScrollLeft".action.focus-column-left = {};
          "${mod}+Ctrl+WheelScrollRight".action.move-column-right= {};
          "${mod}+Ctrl+WheelScrollLeft".action.move-column-left = {};
        };

        #Overview
        overview = {
          zoom = 0.4;
        };
        # Misc
        prefer-no-csd = true;
        screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png";	
        spawn-at-startup = [
          {command = [ "noctalia" ];}
          #start all systemd services tied to the graphical session, e.g, polkit
          {command = ["systemctl" "--user" "start" "graphical-session.target"];} 
        ];

        input = {
          keyboard = {
            xkb = {
              layout = "us";
            };
            repeat-delay = 400;
            repeat-rate = 40;
          };
          focus-follows-mouse.enable = true;
        };
        cursor = {
          hide-after-inactive-ms = 5000;
          theme = "Ukiyo";
          size = 24;
        };
        
        # Layout
        layout = {
          background-color = "transparent";
          gaps = 10;
          center-focused-column = "never";
          preset-column-widths = [
            { proportion = 1.0 / 3.0; }
            { proportion = 1.0 / 2.0; }
            { proportion = 2.0 / 3.0; }
          ];
          default-column-width = { proportion = 1.0 / 2.0; };
          border = {
            enable = false;
            width = 2;
          };

          focus-ring = {
            enable = true;
            width = 10000;
            active.color = "#00000055";
          };

          shadow = {
            enable = true;
            draw-behind-window = true;
          };

          empty-workspace-above-first = true;
        };

        # Animations
        animations = {
          enable = true;
          slowdown = 3;
          window-open = {
            "custom-shader" = builtins.readFile ../../.config/shaders/smoke-window-open.glsl;
          };

          window-close = {
            "custom-shader" = builtins.readFile ../../.config/shaders/smoke-window-close.glsl;
          };

          window-resize = {
            "custom-shader" = builtins.readFile ../../.config/shaders/prism-window-resize.glsl;
          };

        };

      };
         
    };

  };

}
  
