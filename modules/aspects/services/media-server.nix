{den, inputs, ...}:
{
  # 1 define inputs, and add to flake.nix
 flake-file.inputs = {

	# I'll also add nixflix for future better config (and more apps)
	nixflix = {
		url = "github:kiriwalawren/nixflix";
      		inputs.nixpkgs.follows = "nixpkgs";
		#docs https://kiriwalawren.github.io/nixflix/
	};
 };
  
  # 2. Configure tailscale media server
  den.aspects.media-server = {host,...}: {
   nixos = {
    imports = [
      inputs.nixflix.nixosModules.default #added inputs here cause we're in den!
    ];
    mediaServer = {
      enable=true;
      mediaPath = "/data/media";
      #mediaPath = "/share/mnt/data/media";#TODO: change to correct path/dynamic
      openFirewall = false; #use Caddy
    };
    caddyProxy = {
      enable = true;
      mode = "lan";
      tailscaleAccess = {
        enable = true;
        #access from http://<tailscale-ip>:8080
      };
    };
                 
     nixflix = {
				enable = true;
				mediaDir = "/data/media";
				stateDir = "/data/.state";

				mediaUsers = ["myuser"]; #setup ~5 users?
				theme = {
					enable = true;
					name = "overseerr";
				};
				nginx = { #reverse proxy
					enable = true;
					#domain = ;
					addHostsEntries = true; # set to true for local access, false if domain
				};
				postgres.enable = true; #database backend
				sonarr = { # TV shows
					enable = true;
					config = {
						apiKey = {_secret = den.sops.secrets."sonarr/api_key".path;};
						hostConfig.password = {_secret = den.sops.secrets."sonarr/password".path;};
					};
				};
				radarr = { # movies
					enable = true;
					config = {
						apiKey = {_secret = den.sops.secrets."radarr/api_key".path;};
						hostConfig.password = {_secret = den.sops.secrets."radarr/password".path;};
					};
				};
				recyclarr = { #TRaSH guides automation
					enable = true;
					cleanupUnmanagedProfiles = true;    
				};
				lidarr = { #Music
								enable = true;
					config = {
						apiKey = {_secret = den.sops.secrets."lidarr/api_key".path;};
						hostConfig.password = {_secret = den.sops.secrets."lidarr/password".path;};
					};
				};
				prowlarr = { #indexer management with 3 preconfigurations
					enable = true;
					config = {
						apiKey = {_secret = den.sops.secrets."prowlarr/api_key".path;};
						hostConfig.password = {_secret = den.sops.secrets."prowlarr/password".path;};
						indexers = [
							{
								name = "NZBFinder";
								apiKey = {_secret = den.sops.secrets."indexer-api-keys/NZBFinder".path;};          
							}
									
							{
								name = "NzbPlanet";
								apiKey = {_secret = den.sops.secrets."indexer-api-keys/NzbPlanet".path;};
							}
						];
					};    
				};
				jellyfin = { #media streaming
					enable = true;
					users = {
						avanonyme = {
							mutable = false;
											policy.isAdministrator = true;
											password = {_secret = den.sops.secrets."jellyfin/avanonyme_password".path;};
						};
					};
				};
				jellyseerr = { #requests management
					enable = true;
					apiKey = {_secret = den.sops.secrets."jellyseerr/api_key".path;};
				};

				mullvad = { # vpn
					enable = true;
					accountNumber = {_secret = den.sops.secrets.mullvad_account_number.path;};
					location = ["us" "nyc"];
					dns = [
						"94.140.14.14"
						"94.140.15.15"
						"76.76.2.2"
						"76.76.10.2"
						];
					killSwitch = {
					enable = true;
					allowLan = true;
					};
				};     
   }; #nixflix
  }; # nixos
 }; #den aspect
}