{ den, pkgs, config,... }:

    ### Headscale server — include on the NixOS host acting as the coordinator ###
    # Source: https://carlosvaz.com/posts/setting-up-headscale-on-nixos/

let
  baseDomain = "rustedbonghomeserver.mooo.com"; 
  headscaleDomain = "head.${baseDomain}";# TODO: set your domain # admin console
  headscalePort = 8080;
in
{
  den.aspects.headscale = {
    
    # current used Tailscale client is at core.networking
    provides.client ={    
      services.tailscale.enable =  true;
          environment.systemPackages = with pkgs; [
            tailscale
          ];
          #firewall config is per OS
          #nixos
          networking.firewall = {
            # enable the firewall
            enable = true;

            checkReversePath = "loose"; # See https://carlosvaz.com/posts/setting-up-headscale-on-nixos/
            trustedInterfaces = [ "tailscale0" ]; # allow all traffic from the Tailscale interface
            allowedUDPPorts = [ config.services.tailscale.port ];        # allow the Tailscale UDP port through the firewall
            allowedTCPPorts = [ 22 ];  # let you SSH in over the public internet

          };
    };

    provides.server = {
        services.headscale = {
          enable = true;
          address = "127.0.0.1";
          port = headscalePort;
          settings = {
            logtail.enabled = false;
            dns = { 
              base_domain = "tail.${baseDomain}"; # or {baseDomain = "example.com";}
              nameservers.global = [ "1.1.1.1" "9.9.9.9" ];
            };
            server_url = "https://${headscaleDomain}";

          };
        };

        services.nginx = {
          enable = true;
          virtualHosts.${headscaleDomain} = {
            forceSSL = true;
            enableACME = true;
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString headscalePort}";
              proxyWebsockets = true;
            };
          };
        };

        security.acme = {
          acceptTerms = true;
          defaults.email = "admin@example.com"; # TODO: set your email for Let's Encrypt
        };

        # Allow HTTP (ACME challenge) and HTTPS through the firewall
        networking.firewall.allowedTCPPorts = [ 80 443 ];

        environment.systemPackages = [ config.services.headscale.package ];
    };
        
    # After rebuild, run: tailscale up --login-server https://<headscaleDomain>

    # To create a namespace: headscale namespaces create <namespace_name>
    # Register a node: headscale --namespace <namespace_name> nodes register --key <machine_key>

    # To create a user: headscale users create <name>

  };
}
