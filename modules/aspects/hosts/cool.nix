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

      security.sops

      networking.base
      networking.nginx
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
    };


    # Auto-update from git repo (uncomment to enable):
    # systemd.services.nixos-auto-update = {
    #   path = [ pkgs.git pkgs.nix ];
    #   script = ''
    #     cd /var/lib/nixos-config
    #     git pull --ff-only
    #     nixos-rebuild switch --flake .#cool
    #   '';
    #   serviceConfig.Type = "oneshot";
    # };
    # systemd.timers.nixos-auto-update = {
    #   wantedBy = [ "timers.target" ];
    #   timerConfig.OnCalendar = "weekly";
    # };

    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        ghostty
      ];
    };
  };
}
