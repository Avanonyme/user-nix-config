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
    nixos = { pkgs, lib, config, ... }: {
      networking.hostName = "cool";
      networking.hostId = "727b3488";

      networking.useDHCP = lib.mkDefault true;

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
      boot.kernelParams = [ "nomodeset" ];
    };

    # Test microvm guest (uncomment to create a VM on cool):
    # microvm.guests.test-vm = {
    #   config = { ... }: {
    #     imports = [ inputs.microvm.nixosModules.microvm ];
    #     microvm.hypervisor = "qemu";
    #     microvm.socket = "control.socket";
    #     microvm.writableStoreOverlay = "/nix/.rw-store";
    #     microvm.volumes = [{
    #       mountPoint = "/var";
    #       image = "var.img";
    #       size = 256;
    #     }];
    #     microvm.shares = [{
    #       proto = "virtiofs";
    #       tag = "ro-store";
    #       source = "/nix/store";
    #       mountPoint = "/nix/.ro-store";
    #     }];
    #     networking.firewall.enable = false;
    #     services.openssh.enable = true;
    #     users.users.root.password = "";
    #   };
    # };

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
