{ den, pkgs, config,... }:

    ### Headscale server — include on the NixOS host acting as the coordinator ###
    # Source: https://carlosvaz.com/posts/setting-up-headscale-on-nixos/

let
  domain = den.aspects.${config.host.hostName}.domain; # Access the current user aspect dynamically
  headscaleDomain = "head.${domain}";
  tailnetDomain = "tnet.${domain}";
  headscalePort = 8085;
in
{
  den.aspects.headscale = {
    
    # current used Tailscale client is at core.networking
    client ={    
      nixos =
      { lib, pkgs, config,... }:
      # add node to network
      # tailscale up --login-server <headscale_url>
      {

        services.tailscale.enable =  true;
        environment.systemPackages = with pkgs; [
          tailscale
        ];

        networking.firewall = {
          checkReversePath = "loose"; # See https://carlosvaz.com/posts/setting-up-headscale-on-nixos/
          trustedInterfaces = [ "tailscale0" ]; # allow all traffic from the Tailscale interface
          allowedUDPPorts = [ config.services.tailscale.port ];        # allow the Tailscale UDP port through the firewall
          allowedTCPPorts = [ 22 ];  # let you SSH in over the public internet

        };

        services.tailscale.extraUpFlags = ["--ssh"];
      };
      darwin = { pkgs, config, ... }: {
        # 1. Enable the Tailscale daemon
        services.tailscale.enable = true;

        # 2. Add the CLI to your path
        environment.systemPackages = [ pkgs.tailscale ];

        # 3. macOS Firewall (ALF) - Basic enablement
        # Note: macOS doesn't use 'trustedInterfaces' or 'allowedUDPPorts'
        networking.applicationFirewall = {
          enable = true;
          allowSigned = true;
          allowSignedApp = true;
        };

        # 4. Tailscale macOS-specific tweak (Optional)
        # Fixes local DNS issues if MagicDNS isn't working
        services.tailscale.overrideLocalDns = true; 
      };
    };

    server = {
      includes = [den.aspects.nginx];
      nixos = {
            services = { 
              headscale = {
                enable = true;
                address = "127.0.0.1";
                port = headscalePort;
                settings = {
                  logtail.enabled = false;
                  dns = { 
                    magic_dns = true;
                    base_domain = tailnetDomain;
                    nameservers.global = [ "1.1.1.1" "9.9.9.9" ];
                  };
                  server_url = "https://${headscaleDomain}";
                };
                #openID
                oidc = {
                  only_start_if_oidc_is_available = true;
                };
              };

              
              nginx = {
                virtualHosts.${headscaleDomain} = {
                  serverName = "${headscaleDomain}";
                  forceSSL = false;
                  addSSL = true;
                  enableACME = true;
                  useACMEHost = "${domain}";
                  acmeRoot = "/var/lib/acme/challenges-${domain}";
                  locations."/" = {
                    proxyPass = "http://127.0.0.1:${toString headscalePort}";
                    proxyWebsockets = true;
                    recommendedProxySettings = true;
                  };
                };
              };
              security.acme.certs."${domain}".extraDomainNames = ["${headscaleDomain}"];
            };

            #environment.systemPackages = [ config.services.headscale.package ];
          };
        };
        
    # After rebuild, run: tailscale up --login-server https://<headscaleDomain>

    # To create a namespace: headscale namespaces create <namespace_name>
    # Register a node: headscale --namespace <namespace_name> nodes register --key <machine_key>

    # To create a user: headscale users create <name>

  };
}
