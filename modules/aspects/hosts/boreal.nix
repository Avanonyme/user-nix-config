{den, inputs, __findFile, ...}:
{
  # host aspect
  den.aspects.boreal = { #following den (flake-aspects) convention, den.aspects.≤aspect≥.≤class≥
     includes = [
          <core/hostname> #define Hostname
          <core/networking> # networking configuration
          <core/filemanager> #nautilus filemanager and automount
          <core/openssh> #enable services.openssh
          den.aspects.gpu._.amd #subaspect amd of gpu.nix
          den.aspects.boreal_filesystems
          den.aspects.headscale._.server

          den.aspects.noctalia-desktop

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
      
      #systemd boot
      #boot.loader.grub.enable = false;
      #boot.loader.systemd-boot.enable = true;
      #boot.loader.efi.canTouchEfiVariables = true;
      
      # Set static ipv4 address
      #networking.interfaces.eth0.ipv4.addresses = [
      #{
      #  address = "175.142.7.2";
      #  prefixLength = 24;
      #}
      #];
      #networking.defaultGateway = "175.142.7.1";
      #networking.nameservers = ["175.142.7.1"];
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
