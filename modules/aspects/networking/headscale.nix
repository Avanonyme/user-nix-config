{ den, lib, ... }:

    ### Headscale server — include on the NixOS host acting as the coordinator ###
    # Source: https://carlosvaz.com/posts/setting-up-headscale-on-nixos/
    #         https://www.youtube.com/watch?v=ph5zQYx3HS8
let
  tailnet_domain = "tnet.loc";
in
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
      # nix-darwin's services.tailscale has NO authKeyFile/extraUpFlags options
      # (only enable/package/overrideLocalDns), so the NixOS config can't be
      # copied 1:1. Enrollment is done by the activation script below instead.

      # 1. Enable the Tailscale daemon
      services.tailscale ={
        enable = true;
        overrideLocalDns = true; # MagicDNS: sets 100.100.100.100 as resolver
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

      # 4. Auto-enroll into the tailnet on activation (mirrors the NixOS block).
      #    Runs at the end of darwin-rebuild; no-op once logged in (state is
      #    persisted in /var/lib/tailscale across reboots).
      #    Requires a *reusable* auth key in sops (headscale/auth_key) and
      #    settings.networking.headscale.headscaleDomain set on the host.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        ts=${pkgs.tailscale}/bin/tailscale
        state="$($ts status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.BackendState // ""' 2>/dev/null || true)"
        if [ "$state" != "Running" ]; then
          keyfile="${config.sops.secrets."headscale/auth_key".path}"
          if [ -r "$keyfile" ]; then
            echo "tailscale: not logged in — enrolling with headscale..."
            for _ in 1 2 3 4 5; do
              $ts up \
                --auth-key="$(cat "$keyfile")" \
                --login-server="https://${host.settings.networking.headscale.headscaleDomain}" \
                --ssh \
                --reset && break
              sleep 2
            done
          else
            echo "tailscale: $keyfile not readable — enroll manually (see comment in headscale.nix)"
          fi
        fi
      '';
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
              base_domain = "${tailnet_domain}";
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
