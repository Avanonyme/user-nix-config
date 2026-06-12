{den, inputs, __findFile, ...}:
{

 den.aspects.avanonyme = {
    includes = [
			den.provides.define-user
	  	den.provides.primary-user 
      (den.provides.user-shell "fish")
			#den.provides.unfree

			#<core/admin> #handled by primary-user

			den.aspects.noctalia-desktop
      den.aspects.zen-browser
      den.aspects.gaming
			den.aspects.AI
			den.aspects.stylix

			#testing
			den.aspects.gaming.provides.vr

			den.aspects.boreal.provides.to-users
    ];
    nixos ={lib, pkgs, ...}: 
    {
		#normally this logic is handled by den.provides.unfree but error: attribute 'hjem' missing when uncommenting it and nix flake check
		#to disable as well in boreal.nix and gaming.nix
		#--> should we move this to homemanager ?
    nixpkgs.config.allowUnfree = true;

		home-manager.useGlobalPkgs = true; #force home-manager to use nixos modulr pkgs and allow unfree
		home-manager.useUserPackages = true; #pkgs are installed through nixos user

		users.users.avanonyme.openssh.authorizedKeys.keys = [
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBWjooViBeUbs52l0B+9IGlbPTAWXNjtqHUKeq12PMnk avanix26@protonmail.com"
		];	
		users.users.avanonyme.hashedPassword = "$6$WXmKgQx7.qV1slLz$dBZcKato2pr4rST6SWmLnCFd9OdjCYpvl6yq4VFBRXya9mc/LUT9je7npNpNaj4NQmdlRnvwBuQGPL3uP5ow7/";
		
			services.mullvad-vpn = {
				enable = true;
				package = pkgs.mullvad-vpn;
			};

		};
		darwin = {lib,...}:{
			#normally this logic is handled by den.provides.unfree but error: attribute 'hjem' missing when uncommenting it and nix flake check
			#to disable as well in boreal.nix and gaming.nix
			nixpkgs.config.allowUnfree = true;
			#home-manager.useGlobalPkgs = true; #force home-manager to use nixos modulr pkgs and allow unfree
			#home-manager.useUserPackages = true; #pkgs are installed through nixos user

	homebrew.brews = [
		"calibre"

	];
    homebrew.casks = [
        "vlc" 
				"gimp"
				"vscodium"
				"bitwarden"
				"signal"
				"transmission"
				"mullvad-vpn"
				"brave-browser"
      ];
		homebrew.taps = [
		];

		};
    homeManager =
    { pkgs, user, ... }:
		{
			#nix.settings.builders = "ssh://avanonyme@100.x.y.z x86_64-linux - - - - -";

			home.packages = with pkgs; [
			]
			++ lib.optionals stdenv.isLinux [
					bat #moder replacemement for cat
					htop #resources monitoring

					gh #github in the terminal
					#davinci-resolve #video editing 
					neovim
					fastfetch #sys info
					obsidian

					synergy #same keyboard for local network
					tldr
					unzip
					tree #directory visualisation
					vscodium #code editor

					feh #image viewer
					transmission_4-qt #torrent client
					qemu #virtualization
					gimp #image editing
									vlc #media player

					#fonts
					geist-font 
					nerd-fonts.geist-mono

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
		};
	};
}
