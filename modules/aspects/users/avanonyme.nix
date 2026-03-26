{den, __findFile, ...}:
{
 den.aspects.avanonyme = {
    includes = [
      den.aspects.noctalia-desktop
      den.aspects.zen-browser
      den.aspects.gaming
      <vix/admin>
    ];
    nixos ={lib, ...}: 
    {
    	nixpkgs.config.allowUnfree = true;
		home-manager.useGlobalPkgs = true; #force home-manager to use nixos modulr pkgs and allow unfree
		home-manager.useUserPackages = true; #pkgs are installed through nixos user
											
    };

    homeManager =
    { pkgs, user, ... }:
		{
			home.packages = with pkgs; [
				bat #moder replacemement for cat
				btop #resources monitoring
				bitwarden-desktop
				dunst #notif daemon
				feh #image viewer
				gh #github in the terminal
				gimp #image editing
				pitivi #video editing 
				neovim
				fastfetch #sys info
				obsidian
				transmission_4-qt #torrent client
				#qemu #virtualization
				synergy #same keyboard for local network
				tldr
				unzip
				tree #directory visualisation
				vlc #media player
				vscodium #code editor

			];

	programs.git = {
	 enable = true;
	 settings = {
	  user.Name = "avanonyme";
	  user.Email = "avanix26@protonmail.com";
	  extraConfig = {
	    init.defaultBranch = "main";
	    safe.directory = [
				"/home/avanonyme/.dotfiles"
				"/home/avanonyme/vault"
			];
	  };
	 };
	};

				# user can provide NixOS configurations
				# to any host it is included on
				# nixos = { pkgs, ... }: { };

     };
   };
}
