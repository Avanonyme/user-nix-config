{den , ...}:
{
 den.aspects.avanonyme = {
    includes = [
      den.provides.primary-user
      (den.provides.user-shell "fish")
      (den.provides.tty-autologin "root")
      den.aspects.noctalia-desktop
      
    ];

    homeManager =
      { pkgs, user, ... }:
      {
        home.packages = [
   	# bat #moder replacemement for cat
   	# btop #resources monitoring
	# bitwarden-desktop
   	# celluloid #media player
   	# dunst #notif daemon
   	# feh #image viewer
   	# gh #github in the terminal
   	# gimp #image editing
   	# git
   	# lutris #open gaming
   	# nomacs #image editing
   	# neovim
   	# neofetch #sys info
   	# protonup #proton/wine management
   	# obsidian
   	# transmission_4-qt #torrent client
	# qemu #virtualization
   	# synergy #same keyboard for local network
   	# tldr
   	# unzip
   	# tree #directory visualisation
   	# vlc #media player

	];


	programs.git = {
   	 enable = true;
   	 userName = "avanonyme";
   	 userEmail = "avanix26@protonmail.com";
   	 extraConfig = {
    	  init.defaultBranch = "main";
    	  safe.directory = "/home/avanonyme/.dotfiles";
   	 };
        };

    # user can provide NixOS configurations
    # to any host it is included on
    # nixos = { pkgs, ... }: { };

     };
   };
}
