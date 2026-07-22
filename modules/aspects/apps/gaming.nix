 {den, inputs, config, ...}:{ 
 # ─────────────────────────────────────────────────────────────────────────
  # NAMED MODULE EXPORT
  # ─────────────────────────────────────────────────────────────────────────

 den.aspects.apps.gaming = {



    nixos = {pkgs, user, ... }: {
      nixpkgs.config.allowUnfree = true;
      environment.sessionVariables = {
        PROTON_ENABLE_WAYLAND = 1;
      };

      # Steam with Proton support
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;

        extraCompatPackages = with pkgs; [ proton-ge-bin ];
        extraPackages = with pkgs; [ hidapi ];
      };

      # Gamemode for performance optimization
      programs.gamemode = {
        enable = true;
        settings = {
          general = {
            renice = 10;
          };
          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 0;
          };
        };
      };

      # Gamescope compositor
      programs.gamescope = {
        enable = true;
        capSysNice = true;
      };

      # Enable 32-bit libraries for games
      hardware.graphics.enable32Bit = true;

      # Gaming packages
      environment.systemPackages = with pkgs; [
        # Launchers
        faugus-launcher
        heroic
        #lutris #open gaming

        # Proton/Wine
        protonup-qt
        winetricks
        
        # Tools
        mangohud
        gamemode
        
        # Controllers
        sc-controller
        
        # Performance monitoring
        nvtopPackages.amd

        # emulators
        azahar
        cemu
        dolphin-emu
        melonds
        pcsx2
        ppsspp-sdl-wayland
        rmg-wayland
        ryubing
      ];
    };
    darwin = { pkgs, lib, ... }: {
      nixpkgs.config.allowUnfree = true;

      # Steam has no nix-darwin module — install via homebrew cask
      homebrew.casks = [
        "steam"
      ];

      environment.systemPackages = with pkgs; [

      ];
    };

    # User gaming packages via home-manager
    homeManager = { pkgs, lib, user, ... }: {
      # MangoHud config — Linux only, guard so it's not dropped on darwin
      xdg.configFile."MangoHud/MangoHud.conf" = lib.mkIf pkgs.stdenv.isLinux {
        text = ''
          fps
          frametime
          cpu_stats
          gpu_stats
          cpu_temp
          gpu_temp
          ram
          vram
          position=top-left
          font_size=18
          background_alpha=0.4
          round_corners=8
        '';
      };
    };

    vr.nixos = {pkgs, config, host, user, ... }:{
      #https://www.reddit.com/r/NixOS/comments/1re37ky/vr_on_nixos/
      services.monado.enable = true;
      services.monado.defaultRuntime = true;
      services.monado.package =
        with pkgs;
        monado.overrideAttrs (
          finalAttrs: previousAttrs: {
            src = fetchFromGitLab {
              domain = "gitlab.freedesktop.org";
              owner = "thaytan";
              repo = "monado";
        # here you need go to gitlab for this and find most suitable branch for your headset and replace string below
        # or remove whole package override
        #          rev = "dev-wmr-HP-G2-tunnelled-controller";
        #          hash = "sha256-bZBNYKJEegJgm/sDPYsxNCilu8s2ObCGcXAmfrgrmsQ=";
            };

            patches = [ ];
          }
        );

      systemd.user.services.monado.environment = {
        STEAMVR_LH_ENABLE = "1";
        XRT_COMPOSITOR_COMPUTE = "1";
        IPC_EXIT_ON_DISCONNECT = "1";
      };

      programs.steam.package = pkgs.steam.override {
        extraProfile = ''
          # Fixes timezones on VRChat
          unset TZ
          # Allows Monado to be used
          export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
        '';
      };
      # kernel patch for async re projection
      # only works on AMD videocards
      # can be removed if you don't want to recompile your kernel
        boot.kernelPatches = [
        {
          name = "amdgpu-ignore-ctx-privileges";
          patch = pkgs.fetchpatch {
            name = "cap_sys_nice_begone.patch";
            url = "https://github.com/Frogging-Family/community-patches/raw/master/linux61-tkg/cap_sys_nice_begone.mypatch";
            hash = "sha256-Y3a0+x2xvHsfLax/uwycdJf3xLxvVfkfDVqjkxNaYEo=";
          };
        }
      ];

      # OpenXR discovery
      home-manager.users."${user.userName}" = {
        xdg.configFile."openxr/1/active_runtime.json".source =
          "${config.services.monado.package}/share/openxr/1/openxr_monado.json";
        home.file.".local/share/monado/hand-tracking-models".source = pkgs.fetchgit {
          url = "https://gitlab.freedesktop.org/monado/utilities/hand-tracking-models";
          sha256 = "sha256-x/X4HyyHdQUxn3CdMbWj5cfLvV7UyQe1D01H93UCk+M=";
          fetchLFS = true;
        };
        xdg.configFile."openvr/openvrpaths.vrpath".text = builtins.toJSON {
          config = [ "${config.home-manager.users."${user.userName}".xdg.dataHome}/Steam/config" ];
          external_drivers = null;
          jsonid = "vrpathreg";
          log = [ "${config.home-manager.users."${user.userName}".xdg.dataHome}/Steam/logs" ];
          runtime = [ "${pkgs.opencomposite}/lib/opencomposite" ];
          version = 1;
        };
      };

      environment.systemPackages = [
      # provides hello_xr for testing VR
        pkgs.openxr-loader
      ];
    };
  };
 }
