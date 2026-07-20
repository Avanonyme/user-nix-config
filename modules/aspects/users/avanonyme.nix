{den, inputs, __findFile, ...}:
{

 den.aspects.avanonyme.headless = {
		includes = [
			den.provides.define-user
	  	den.provides.primary-user 
      (den.provides.user-shell "fish")
		];
		nixos ={lib, pkgs, ...}: 
    {

		home-manager.useGlobalPkgs = true; #force home-manager to use nixos modulr pkgs and allow unfree
		home-manager.useUserPackages = true; #pkgs are installed through nixos user

		users.users.avanonyme.openssh.authorizedKeys.keys = [
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBWjooViBeUbs52l0B+9IGlbPTAWXNjtqHUKeq12PMnk avanix26@protonmail.com"
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE0zIwouEtcJIHzE0qPLOBY53ha89FszBC9TlUVrEAjm avanonyme@cool"
		];	
		#or 
		# users.users."user".openssh.authorizedKeys.keyFiles = [
  	#		/etc/nixos/ssh/authorized_keys
		#	];

		# TODO: change to an encrypted secrets (already in secrets.yaml) 
		users.users.avanonyme.hashedPassword = "$6$WXmKgQx7.qV1slLz$dBZcKato2pr4rST6SWmLnCFd9OdjCYpvl6yq4VFBRXya9mc/LUT9je7npNpNaj4NQmdlRnvwBuQGPL3uP5ow7/";

		};
		homeManager = {
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
 den.aspects.avanonyme.desktop = {
    includes = with den.aspects; [
			avanonyme.headless
			
			desktop.noctalia
			app-bundles.full

			#testing
			#apps.gaming.vr
    ];
		
			#normally this logic is handled by den.provides.unfree but error: attribute 'hjem' missing when uncommenting it and nix flake check
			#to disable as well in boreal.nix and gaming.nix
			#--> should we move this to homemanager ?
		nixos.nixpkgs.config.allowUnfree = true;

		darwin.nixpkgs.config.allowUnfree = true;
			
    homeManager =
    { pkgs, user, ... }:
		{
			#nix.settings.builders = "ssh://avanonyme@100.x.y.z x86_64-linux - - - - -";
		};
	};

}
