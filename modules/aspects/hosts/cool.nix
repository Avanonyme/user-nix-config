{ den, inputs, lib, __findFile, ... }:
{
  #16gb ram
  den.aspects.cool = {
    settings.domain = {
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
      networking.base
      core.openssh
      disk.cool
      #den.aspects.headscale.server
      #den.aspects.headscale._.client
      security.sops
      virtualization.microvm-bridge
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

      microvm.vms."igloo" = {
        # Mount the secret into the VM so it can decrypt its own secrets on boot
        shares = [{
          source = config.sops.secrets."microvm/igloo_age_key".path;
          mountPoint = "/var/lib/sops-age.key";
          tag = "igloo-age-key";
          proto = "virtiofs";
        }];

        config = {
          # The VM configuration
          sops.age.keyFile = "/var/lib/sops-age.key";
          sops.defaultSopsFile = ../../../secrets/secrets.yaml;
          
          # Now the VM can decrypt the OIDC secret and admin password!
          sops.secrets."kanidm/admin_password" = { owner = "kanidm"; };
          sops.secrets."kanidm/headscale_oidc_secret" = { owner = "headscale"; };
        };
      };

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
