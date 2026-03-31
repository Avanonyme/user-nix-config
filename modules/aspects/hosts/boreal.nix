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
          den.aspects.disko-boreal
          
        ];
    # host NixOS configuration
    nixos =
    { pkgs, lib, ... }:
    {
      #TODO define device names for disko-boreal
      disko.devices.disk.root.device = "/dev/sdb";
      disko.devices.disk.data1.device = "/dev/sda";
      disko.devices.disk.data2.device = "/dev/sdc";
      # Bootloader. #TODO move to boot module
      # grub boot
      boot.loader.grub = {
        enable = true;
        # no need to set devices, disko will add all devices that have a EF02 partition to the list already
        # devices = [ ];
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
      
      #systemd boot
      #boot.loader.grub.enable = false;
      #boot.loader.systemd-boot.enable = true;
      #boot.loader.efi.canTouchEfiVariables = true;
      boot.supportedFilesystems = [ "zfs" ];
      networking.hostId = "002bf327"; # required by ZFS — generate with: head -c4 /dev/urandom | od -A none -t x4 | tr -d ' '

      #a priori this is not needed (defined in den.nix with host/user/home)
      #nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      #TODO: move to a disko filesystem aspect
      #fileSystems."/" =
      #  { device = "/dev/disk/by-uuid/1717c128-b9fa-45ce-9e75-f1e163387351";
      #    fsType = "ext4";
      #  };

      #swapDevices = [ ]; #can we remove this for disko config?

      # Set static ipv4 address
      #networking.interfaces.eth0.ipv4.addresses = [
      #{
      #  address = "175.142.7.2";
      #  prefixLength = 24;
      #}
      #];
      #networking.defaultGateway = "175.142.7.1";
      #networking.nameservers = ["175.142.7.1"];

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
