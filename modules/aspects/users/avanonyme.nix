{den, __findFile, ...}:
{
 den.aspects.avanonyme = {
    includes = [
	  den.provides.primary-user
      (den.provides.user-shell "fish")
			#den.provides.unfree

			<core/admin>

      den.aspects.noctalia-desktop
      den.aspects.zen-browser
      den.aspects.gaming
    
    ];
    nixos ={lib, ...}: 
    {
		#normally now this logic is handled by den.provides.unfree but error: attribute 'hjem' missing when uncommenting it and nix flake check
		#to disable as well in boreal.nix and gaming.nix
    	nixpkgs.config.allowUnfree = true;
		home-manager.useGlobalPkgs = true; #force home-manager to use nixos modulr pkgs and allow unfree
		home-manager.useUserPackages = true; #pkgs are installed through nixos user

		users.users.avanonyme.openssh.authorizedKeys.keys = [
			ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBWjooViBeUbs52l0B+9IGlbPTAWXNjtqHUKeq12PMnk avanix26@protonmail.com
		];				
    };

    homeManager =
    { pkgs, user, ... }:
		{
			home.packages = with pkgs; [
				bat #moder replacemement for cat
				htop #resources monitoring
				bitwarden-desktop
				dunst #notif daemon
				feh #image viewer
				gh #github in the terminal
				gimp #image editing
				davinci-resolve #video editing 
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
