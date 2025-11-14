# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{pkgs, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdc";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos-avano"; # Define your hostname.
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  
  # Set static ipv4 address
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

  # Graphics and GPU settings
  services.xserver.enable = true;
  services.xserver.videoDrivers = ["nvidia"];

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  }; #hardware.opengl has been changed to hardware.graphics

  nixpkgs.config.nvidia.acceptLicense = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;  # Important: Disable open-source driver
    nvidiaSettings = true;
#    package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
  };



  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "ca";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.avanonyme = {
    isNormalUser = true;
    description = "avanonyme";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    alacritty
    brave
    git
    wget
    neovim
    niri
    mangohud
    linux-firmware
    steam
#    steam-original
#    steam-unwrapped
    steam-run
    xwayland-satellite
  ];


  # Desktop Environment.
  programs.niri.enable = true;

#  stylix.enable = true;
  # you can choose after running 'nix build nixpkgs#base16-schemes'cd result'nix run nixpkgs#eza -- --tree'
  #stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
  #for now we hardcode the scheme
#  stylix.base16Scheme = {
#    base00 = "282828";
#    base01 = "3c3836";
#    base02 = "504945";
#    base03 = "665c54";
#    base04 = "bdae93";
#    base05 = "d5c4a1";
#    base06 = "ebdbb2";
#    base07 = "fbf1c7";
#    base08 = "fb4934";
#    base09 = "fe8019";
#    base0A = "fabd2f";
#    base0B = "b8bb26";
#    base0C = "8ec07c";
#    base0D = "83a598";
#    base0E = "d3869b";
#    base0F = "d65d0e";
#  };
  #this has to be declared
#  stylix.image = ./images/stylix-background.png;
  #more option at https://nix-community.github.io/stylix/


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    allowSFTP = true;
  };

  #backup window manager if niri fails
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
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
