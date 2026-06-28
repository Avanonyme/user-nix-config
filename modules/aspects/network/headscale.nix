{ den, lib, ... }:

    ### Headscale server — include on the NixOS host acting as the coordinator ###
    # Source: https://carlosvaz.com/posts/setting-up-headscale-on-nixos/
{
  den.aspects.networking.headscale.client = {
    nixos =
    { lib, pkgs, config, ... }:
    # add node to network
    # tailscale up --login-server <headscale_url>
    {
      services.tailscale.enable = true;
      environment.systemPackages = with pkgs; [
        tailscale
      ];

      networking.firewall = {
        checkReversePath = "loose"; # See https://carlosvaz.com/posts/setting-up-headscale-on-nixos/
        trustedInterfaces = [ "tailscale0" ]; # allow all traffic from the Tailscale interface
        allowedUDPPorts = [ config.services.tailscale.port ]; # allow the Tailscale UDP port through the firewall
      };

      services.tailscale.extraUpFlags = ["--ssh"];
    };
    darwin = { pkgs, ... }: {
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

  den.aspects.networking.headscale.server = {
    settings = {
      headscaleDomain = lib.mkOption {
        type = lib.types.str;
        description = "Full headscale domain (e.g. head.example.com)";
      };
      headscalePort = lib.mkOption {
        type = lib.types.port;
        default = 8085;
        description = "Port for headscale (default 8085)";
      };
      tailnetDomain = lib.mkOption {
        type = lib.types.str;
        description = "Tailnet DNS domain (e.g. tnet.example.com)";
      };
    };

    includes = with den.aspects; [
      networking.nginx
    ];

    nixos = { host, config, ... }: let
      headscaleDomain = host.settings.networking.headscale.server.headscaleDomain;
      headscalePort = host.settings.networking.headscale.server.headscalePort;
      tailnetDomain = host.settings.networking.headscale.server.tailnetDomain;
    in {
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
          oidc = {
            only_start_if_oidc_is_available = true;
          };
        };

        kanidm.provision.systems.oauth2.headscale = {
            displayName = "vpn";
            originUrl = [
              "https://${headscaleDomain}/oidc/callback"
              "https://${headscaleDomain}/admin/oidc/callback"
            ];
            originLanding = "https://${headscaleDomain}/admin";
            basicSecretFile = config.sops.secrets."kanidm/headscale_oidc_secret".path;
            scopeMaps."vpn.users" = [ "openid" "email" "profile" ];
            preferShortUsername = true;
          };
        nginx.virtualHosts."${headscaleDomain}" = {
          serverName = headscaleDomain;
          forceSSL = false;
          addSSL = true;
          enableACME = true;
          useACMEHost = "${headscaleDomain}";
          acmeRoot = "/var/lib/acme/challenges-${headscaleDomain}";
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString headscalePort}";
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
        };
      };

      security.acme.certs."${headscaleDomain}" = {
        webroot = "/var/lib/acme/challenges-${headscaleDomain}";
        email = host.settings.${host.hostName}.admin_email; 
        group = "nginx";
      };
    };
  };
}

# After rebuild, run: tailscale up --login-server https://<headscaleDomain>

# To create a namespace: headscale namespaces create <namespace_name>
# Register a node: headscale --namespace <namespace_name> nodes register --key <machine_key>

# To create a user: headscale users create <name>
