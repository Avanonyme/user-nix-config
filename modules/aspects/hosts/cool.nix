{ den, inputs, lib, __findFile, ... }:
{
  #16gb ram
  den.aspects.cool = {
    settings = {
        basedomain = lib.mkOption {
          type = lib.types.str;
          description = "Your domain name";
        };     
        admin_email = lib.mkOption {
          type = lib.types.str;
          description = "Your email admin";
        };    
    };

    includes = with den.aspects; [
      core.hostname
      core.openssh

      disk.cool
      disk.gc

      security.sops

      networking.base
      networking.headscale.client
      networking.ddclient


      virtualization.microvm-bridge
      virtualization.microvms.sealskin
    ];

    # Host NixOS configuration
    nixos = { host, pkgs, lib, config, inputs, ... }: {
      networking.hostName = "cool";
      networking.hostId = "727b3488";

      networking.useDHCP = lib.mkDefault false;
      networking.interfaces.enp1s0.ipv4.addresses = [{
        address = "192.168.50.2";
        prefixLength = 24;
      }];
      networking.defaultGateway = "192.168.50.1";
      networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
      networking.networkmanager.unmanaged = [ "interface-name:enp1s0" ];

      nix.settings.experimental-features = ["nix-command" "flakes"];
      nix.settings.trusted-users = [ "avanonyme" ];

      # Remote builder: allow incoming builds from tailnet
      nix.settings.max-jobs = 4;
      nix.buildMachines = []; # this is the builder, not a client

      environment.systemPackages = with pkgs; [
        vim
        git
        htop
      ];

      # TODO: set timezone
      time.timeZone = "America/Toronto";

      nixpkgs.config.allowUnfree = true;


      boot.loader.grub = {
        enable = true;
        devices = [ "nodev" ]; # EFI-only install; disko only auto-adds devices for EF02 (BIOS boot) partitions
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
      boot.kernelParams = [ "nomodeset" ];   #its an old computer 

      # Daily reboot at 05:00 (local) — clears stuck tailscaled/headscale/microvm
      # state so a failure while you're away self-heals within 24h.
      # sealskin has autostart = true, so the headscale microvm comes back up
      # on its own after each reboot.
      systemd.timers.daily-reboot = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 05:00:00"; # system timezone (America/Toronto)
          Persistent = true;             # catch up if the machine was off
        };
      };
      systemd.services.daily-reboot = {
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.systemd}/bin/systemctl reboot
        '';
      };

      # Optional — actually refresh the config daily from git + reboot if the
      # generation changed. Needs cool to have read access to the repo (it's
      # private: use a read-only deploy key in /root/.ssh, or make it public).
      # system.autoUpgrade = {
      #   enable = true;
      #   flake = "github:Avanonyme/user-nix-config/main#cool";
      #   dates = "04:30";               # runs before the 05:00 reboot
      #   allowReboot = true;
      #   rebootWindow = { lower = "04:00"; upper = "06:00"; };
      #   operation = "switch";          # or "boot" to only activate on reboot
      # };
    };

    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        ghostty
      ];
    };
  };
}
