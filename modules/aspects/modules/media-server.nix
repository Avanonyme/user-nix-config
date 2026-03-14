{den, inputs, ...}:
{
  # 1 define inputs, and add to flake.nix
 flake-file.inputs = {
	reticulum-flake = {
   		url = "git+https://codeberg.org/adingbatponder/reticulum_nixos_flake.git";
   		inputs.nixpkgs.follows = "nixpkgs"; 
 	};
	# I'll also add nixflix for future better config (and more apps)
	nixflix = {
		url = "github:kiriwalawren/nixflix";
      		inputs.nixpkgs.follows = "nixpkgs";
	};
 };
  
  # 2. Configure tailscale media server
  den.aspects.media-server = {host,...}: {
   nixos = {
    imports = [
      "${inputs.reticulum-flake}/parts/media-server.nix"
      inputs.nixflix.nixosModules.nixflix #added inputs here cause we're in den!


    ];
    mediaServer = {
      enable=true;
      mediaPath = "/data/media";
      #mediaPath = "/home/${user}/media";#TODO: change to correct path/dynamic
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

	mediaUsers = ["myuser"];
	theme = {
		enable = true;
		name = "overseerr";
	};

    
	nginx = {
		enable = true;
		addHostsEntries = true; # Disable this is you have your own DNS configuration
	};

	postgres.enable = true;

    
	sonarr = { 
		enable = true;
      
		config = {
			apiKey = {_secret = den.sops.secrets."sonarr/api_key".path;};
        		hostConfig.password = {_secret = den.sops.secrets."sonarr/password".path;};
		};
};
 
	radarr = {
      		enable = true;
			config = {
				apiKey = {_secret = den.sops.secrets."radarr/api_key".path;};
				hostConfig.password = {_secret = den.sops.secrets."radarr/password".path;};
			};
		};

    
	recyclarr = {
		enable = true;
		cleanupUnmanagedProfiles = true;    
	};

	lidarr = {
      		enable = true;
		config = {
			apiKey = {_secret = den.sops.secrets."lidarr/api_key".path;};
     		        hostConfig.password = {_secret = den.sops.secrets."lidarr/password".path;};
			};
		};

    
	prowlarr = {
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

	jellyfin = {
		enable = true;
		users = {
			avanonyme = {
				mutable = false;
          			policy.isAdministrator = true;
          			password = {_secret = den.sops.secrets."jellyfin/avanonyme_password".path;};
			};
		};
	};

    
	jellyseerr = {
		enable = true;
		apiKey = {_secret = den.sops.secrets."jellyseerr/api_key".path;};
	};

    	mullvad = {
		enable = true;
			accountNumber = {_secret = den.sops.secrets.mullvad-account-number.path;};
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
    
             
    
              
    
                         
    
                          
    
                        

    
         
      
              
      
                   
    


    
         
      
              
      
                                                                             
    
  

            
               

    
          
      
              
      
          
        
                                                                
                  
                                                                    
      
  
    
  

    
          
      
              
      
          
        
                                                                
                  
                                                                    
      
  
    
  

    
             
      
              
      
                                
    
  

    
          
      
              
      
          
        
                                                                
                  
                                                                    
      
  
    
  

    
            
      
              
      
          
        
                                                                  
                  
                                                                      
        
            
          
 
            
                     
            
                                                                              
          
 
          
 
            
                   
            
                                                                            
          
 
          
 
            
                   
            
                                                                            
          
 
        
  
      
  
    
  

    
           
      
              

      
            
        
        
          
                                                                  
          
                                                                  
        
  

        
           
          
 
            
               
            
                            
            
           
            
                                         
            
                                                                         
            
                                                                         
            
                 
            
           
            
             
            
                 
          
 
          
 
            
                         
            
                                  
            
           
            
                                                                                   
            
                                                                                   
            
                 
            
           
            
             
            
                
            
              
          
 
        
  
      
  
    
  

    
            
      
              
      
         
        
         
          
                
                
                        
          
                                                                           
        
  
      
  
    
  

    
              
      
              
      
                                                                    
    
  

    
           
      
              
      
                                                                             
      
                        
      
       
        
              
        
              
        
           
        
            
      
  
      
              
        
              
        
                
      
  
    
