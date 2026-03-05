{den, inputs, __findFile, ...}:
{
  # host aspect
  den.aspects.boreal = { #following den (flake-aspects) convention, den.aspects.≤aspect≥.≤class≥
     includes = [
          <vix/hostname> #define Hostname
          <vix/networking> # networking configuration
#          den.aspects.nvidia
          
        ];
    # host NixOS configuration
    nixos =
      { pkgs, lib, ... }:
      {
        # Bootloader.
          boot.loader.grub.enable = false;
        # boot.loader.grub.device = "/dev/sda1";
        # boot.loader.grub.useOSProber = true;
          boot.loader.systemd-boot.enable = true;
	  boot.loader.efi.canTouchEfiVariables = true;
	  
        #Kernel; more options in nvidia aspect
	boot.initrd.kernelModules = ["amdgpu"];
        boot.kernelModules = [ "kvm-intel" ];

        #a priori this is not needed (defined in den.nix with host/user/home)
        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

        #TODO: move to a disko filesystem aspect
        fileSystems."/" =
          { device = "/dev/disk/by-uuid/1717c128-b9fa-45ce-9e75-f1e163387351";
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
	

	#set graphics
	services.xserver.videoDrivers = ["amdgpu"];
	hardware.firmware = [ pkgs.linux-firmware ]; #for Error: Direct firmware load failure
	hardware.graphics = {
	  enable = true;
	  enable32Bit = true;
	};
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
