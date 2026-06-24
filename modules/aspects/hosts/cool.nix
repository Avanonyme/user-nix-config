{ den, inputs, __findFile, ... }:
{
  #16gb ram
  den.aspects.cool = {
    
    domain = "rustedbonghomeserver.mooo.com"; 


    includes = with den.aspects; [
      core.hostname
      network.base
      core.openssh
      disk.cool
      #den.aspects.headscale.server
      #den.aspects.headscale._.client
      sops
      microvm
     # den.aspects.ipfs-media._.gateway
    ];

    # Host NixOS configuration
    nixos = { pkgs, lib, config, inputs, ... }: {
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
    avanonyme.includes = with den.aspects; [avanonyme.headless];
  };
}
