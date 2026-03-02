{den, inputs, __findFile, ...}:
{
  # host aspect
  den.aspects.boreal = { #following den (flake-aspects) convention, den.aspects.≤aspect≥.≤class≥
     includes = [
          <vix/hostname> #define Hostname
          <vix/networking> # networking configuration
          den.aspects.nvidia
          
        ];
    # host NixOS configuration
    nixos =
      { pkgs, lib, ... }:
      {
        # Bootloader.
         boot.loader.grub.enable = true;
         boot.loader.grub.device = "/dev/sda1";
         boot.loader.grub.useOSProber = true;
        # boot.loader.systemd-boot.enable = true;
	# boot.loader.efi.canTouchEfiVariables = true;

        #Kernel; more options in nvidia aspect
        boot.kernelModules = [ "kvm-intel" ];

        #a priori this is not needed (defined in den.nix with host/user/home)
        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

        #TODO: move to a disko filesystem aspect
        fileSystems."/" =
          { device = "/dev/disk/by-uuid/b3fbba01-1206-44d9-9b15-72e6313b4f72";
            fsType = "ext4";
          };

        swapDevices = [ ];
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

        # List services that you want to enable:

          # Enable the OpenSSH daemon.
          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "no";
            allowSFTP = true;
          };
      };


    # host provides default home environment for its users
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs;[ 
          vim 
          kitty
        ];
      };
  };
}
