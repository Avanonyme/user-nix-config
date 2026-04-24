{ den, ... }:

    ### Headscale server — include on the NixOS host acting as the coordinator ###
    # Source: https://carlosvaz.com/posts/setting-up-headscale-on-nixos/

let
  headscaleDomain = "rustedbonghomeserver.mooo.com"; # TODO: set your domain # admin console
  headscalePort = 8080;
in
{
  den.aspects.headscale = {
    
    # Tailscale client is at core.networking
    # After rebuild, run: tailscale up --login-server https://<headscaleDomain>

    # To create a namespace: headscale namespaces create <namespace_name>
    # Register a node: headscale --namespace <namespace_name> nodes register --key <machine_key>

    # To create a user: headscale users create <name>

    provides.server = {
      nixos = { pkgs, config, ... }: {
        services.headscale = {
          enable = true;
          address = "127.0.0.1";
          port = headscalePort;
          settings = {
            logtail.enabled = false;
            dns = { 
              base_domain = "rustedbonghomeserver.mooo.com"; # or {baseDomain = "example.com";}
              nameservers.global = ["mooo.com"];
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
    };
  };
}
