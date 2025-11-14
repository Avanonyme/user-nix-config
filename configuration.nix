# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib ,... }:
let
 home-manager = builtins.fetchTarball { 
  url = "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz";
  sha256 = "0q3lv288xlzxczh6lc5lcw0zj9qskvjw3pzsrgvdh8rl8ibyq75s";
 };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix 
      (import "${home-manager}/nixos")
    ];

  #home manager setup
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "backup";
  home-manager.users.avanonyme = import ./home.nix;
  
  # Bootloader.
   #blacklist nouveau so that it doesnt install instead of legacy
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.extraModprobeConfig = ''
  blacklist nouveau
  options nouveau modeset=0
'';
  
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/EFI";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  #graphics
  services.xserver.enable = true;
  services.xserver.videoDrivers = ["nvidia"];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  }; #hardware.opengl has been changed to hardware.graphics

  nixpkgs.config.nvidia.acceptLicense = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;  # Important: Disable Nouveau driver
    nvidiaSettings = true;
 #   package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
  };
 

### Networking

  networking.hostName = "nixos"; # Define your hostname.
 #  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  #set static ipv4 address
  networking.interfaces.eth0.ipv4.addresses = [
   {
    address = "175.142.7.2";
    prefixLength = 24;
   }
  ];
  networking.defaultGateway = "175.142.7.1";
  networking.nameservers = ["175.142.7.1"];


  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "ca";
    variant = "";
  };
 
 #Enable Emacs daemon
 services.emacs = {
  enable = true;
  package = pkgs.emacs;
 };
  # Configure console keymap
  console.keyMap = "cf";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
    services.libinput.enable = true;
  # Enable usb services
    services.gvfs.enable = true;
    services.udisks2.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.avanonyme = {
    isNormalUser = true;
    description = "Avanonyme";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };
 
  #Install steam global (changes hardware settings so need global install?)
  programs.steam = {
   enable = true;
   remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
   dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
   gamescopeSession.enable = true;
   };

  programs.gamemode.enable = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-unwrapped"
    "steam-run"
  ];

  #Packages

  nix.settings.experimental-features = ["nix-command" "flakes"];
  # List packages installed in system profile. To search, run:
  # $ nix search wget
 environment.systemPackages = with pkgs; [
    brave
    vim
    wget
    neovim
    mangohud
    linux-firmware
  ];


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
 services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
