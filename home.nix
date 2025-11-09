{ config, pkgs, lib,... }:
 # this file is being progressively replaced by other files (sh.nix and programs,nix)
{
  imports = [
 #  ./sh.nix
 #  ./hyprland.nix
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "avanonyme";
  home.homeDirectory = "/home/avanonyme";
  home.stateVersion = "25.05"; # do not change (keep coherent with configuration.nix)

  programs.zsh = {
   enable = true;
   shellAliases = {
    nrs = "nixos-rebuild switch";
   };
   envExtra = "export PS1=`%{$(tput setaf 47)%}%n%{$(tput setaf 156)%}@%{$(tput setaf 227)%}%m %{$(tput setaf 231)%}%1~ %{$(tput sgr0)%}$`";

 
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
   bat #moder replacemement for cat
   btop #resources monitoring
   bitwarden-desktop
   celluloid #media player
   dunst #notif daemon
   feh #image viewer
   flameshot #screenshot
   gh #github in the terminal
   gimp #image editing
   git
   kitty #terminal
   lutris #open gaming
   minecraft
   nomacs #image editing
   neovim
   neofetch #sys info
   protonup
   obsidian
   transmission_4-qt
   qemu #virtualization
   synergy #same keyboard for local network
   tldr
   unzip
   variety
   tree

  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager.

  #home.file.".config/hypr/hyprland.conf".source = ./hyprland.conf;
  # Let Home Manager install and manage itself.

  programs.home-manager.enable = true;

  home.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS =
      "\\\${HOME}/.steam/root/compatibilitytools.d";
  };

  programs.git ={
   enable = true;
   userName = "avanonyme";
   userEmail = "avanix26@protonmail.com";
   extraConfig = {
    init.defaultBranch = "main";
    safe.directory = "/home/avanonyme/.dotfiles";
   };
  };
# services.transmission = { 
#    enable = true; #Enable transmission daemon
#    openRPCPort = true; #Open firewall for RPC
#    settings = { #Override default settings
#      rpc-bind-address = "0.0.0.0"; #Bind to own IP
#      rpc-whitelist = "127.0.0.1,10.0.0.1"; #Whitelist your remote machine (10.0.0.1 in this example)
#    };
#  };

}
