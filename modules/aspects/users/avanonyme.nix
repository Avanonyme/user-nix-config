{den, vix, ...}:
{
 den.aspects.avanonyme = {
    includes = [
      den.aspects.noctalia-desktop
      den.aspects.zen-browser
			<vix/admin>
    ];
    nixos ={lib, ...}: 
    {
 #    services.xserver = {
#	enable =true;
#	desktopManager = {
#	 xterm.enable =false;
#	 xfce.enable = true;
#	};
 #    };
 #    services.displayManager = {
 #     defaultSession = lib.mkDefault "xfce";
 #     enable = true;
 #    };
	nixpkgs.config.allowUnfree = true;
    };

    homeManager =
      { pkgs, user, ... }:
      {
        home.packages = with pkgs; [
   	 bat #moder replacemement for cat
   	 btop #resources monitoring
	 bitwarden-desktop
   	 celluloid #media player
   	 dunst #notif daemon
   	 feh #image viewer
   	 gh #github in the terminal
   	 gimp #image editing
   	# lutris #open gaming
   	 nomacs #image editing
   	 neovim
   	 neofetch #sys info
   	 protonup-ng #proton/wine management
   	# obsidian
   	 transmission_4-qt #torrent client
	 qemu #virtualization
   	 synergy #same keyboard for local network
   	 tldr
   	 unzip
   	 tree #directory visualisation
   	 vlc #media player

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
