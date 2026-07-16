{ den, lib, ... }:

    ### Headscale server — include on the NixOS host acting as the coordinator ###
    # Source: https://carlosvaz.com/posts/setting-up-headscale-on-nixos/
    #         https://www.youtube.com/watch?v=ph5zQYx3HS8
{
  den.aspects.networking.headscale.settings = {
    headscaleDomain = lib.mkOption {
      type = lib.types.str;
      description = "Full headscale domain (e.g. head.example.com)";
    };
    headscalePort = lib.mkOption {
      type = lib.types.port;
      default = 8085;
      description = "Port for headscale (default 8085)";
    };
  };

  den.aspects.networking.headscale.client = {
  /*
  Manual Enrollment (in flake directory with correct decryption keys):

  sudo tailscale up \
  --auth-key="$(sudo cat "$(nix eval --raw .#darwinConfigurations.arctic.config.sops.secrets.headscale/auth_key.path)")" \
  --login-server="https://rustedbonghomeserver.mooo.com" \
  --ssh
  tailscale status
  tailscale netcheck

  */
    nixos =
    { host,lib, pkgs, config, ... }:

    {
      services.tailscale ={
        enable = true;
        authKeyFile = config.sops.secrets."headscale/auth_key".path;
        extraUpFlags = ["--ssh" "--login-server=${host.settings.networking.headscale.headscaleDomain}"];
      };
      environment.systemPackages = with pkgs; [
        tailscale
      ];

      networking.firewall = {
        checkReversePath = "loose"; # See https://carlosvaz.com/posts/setting-up-headscale-on-nixos/
        trustedInterfaces = [ "tailscale0" ]; # allow all traffic from the Tailscale interface
        allowedUDPPorts = [ config.services.tailscale.port ]; # allow the Tailscale UDP port through the firewall
      };
    };
    darwin = { host,lib, pkgs, config, ... }: {
      # 1. Enable the Tailscale daemon
      services.tailscale ={
        enable = true;
        openFirewall = true;

        authKeyFile = config.sops.secrets."headscale/auth_key".path;
        extraUpFlags = ["--ssh" "--login-server=${host.settings.networking.headscale.headscaleDomain}"];
      };
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

    includes = with den.aspects; [
      networking.nginx 
    ];

    nixos = { host, config, lib, ... }: let
      headscaleDomain = host.settings.networking.headscale.headscaleDomain;
      headscalePort = host.settings.networking.headscale.headscalePort;
    in {
      services = {
        headscale = {
          enable = true;
          address = "0.0.0.0";
          port = headscalePort;
          settings = {
            logtail.enabled = false;
            dns = {
              magic_dns = true;
              base_domain = "tnet.loc";
              nameservers.global = [ "1.1.1.1" "9.9.9.9" ];
            };
            server_url = "https://${headscaleDomain}";
            policy.path = ../../.config/acl.hujson;
          };
        };
        
        nginx.virtualHosts."${headscaleDomain}" = lib.mkForce {
          serverName = headscaleDomain;
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString headscalePort}";
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
        };
      };
    };
  };
}

# After rebuild, run: tailscale up --login-server https://<headscaleDomain>

# To create a namespace: headscale namespaces create <namespace_name>
# Register a node: headscale --namespace <namespace_name> nodes register --key <machine_key>

# To create a user: headscale users create <name>
