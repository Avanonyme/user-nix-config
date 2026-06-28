{den, inputs, __findFile, ...}:
{
  # host aspect
  den.aspects.boreal = { #following den (flake-aspects) convention, den.aspects.≤aspect≥.≤class≥
     includes = with den.aspects; [
          core.hostname #define Hostname
          core.filemanager #nautilus filemanager and automount
          core.openssh #enable services.openssh
          networking.base
          gpu.amd #subaspect amd of gpu.nix
          disk.boreal
          networking.headscale.client
          security.sops
         # ipfs-media.peer


        ];

    # host NixOS configuration
    nixos =
    { pkgs, lib, ... }:
    {
      # Bootloader. #TODO move to boot module
      # grub boot
      boot.loader.grub = {
        enable = true;
        devices = [ "nodev" ]; # EFI-only install; disko only auto-adds devices for EF02 (BIOS boot) partitions
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
      
      networking.hostId = "002bf327"; # required by ZFS — generate with: head -c4 /dev/urandom | od -A none -t x4 | tr -d ' '

      # Set your time zone.
      time.timeZone = "America/Toronto";
      
      fonts.packages = with pkgs; [
        ubuntu-classic
        liberation_ttf
      ]; 
  
      # Select internationalisation properties.
      i18n.defaultLocale = "en_CA.UTF-8";
      
      #allow unfree packages
      nixpkgs.config.allowUnfree = true;
      nix.settings.experimental-features = ["nix-command" "flakes"];

      environment.systemPackages = with pkgs; [ 
        vim
        git
        wget
  
      ];

      home-manager.backupFileExtension = "hm.OLD";

    };

    # host provides default home environment for its users
    homeManager =
    { pkgs, ... }:
    {
      
      home.packages = with pkgs;[ 
        ghostty
      ];


    };
  };
}
