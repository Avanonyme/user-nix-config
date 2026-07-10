{den,...}:{
  den.aspects.networking.tailscale.client = {
    nixos =
    { host, lib, pkgs, config, ... }:

    {
      services.tailscale ={
        enable = true;
        #authKeyFile = config.sops.secrets."tailscale/auth_key".path;
        extraUpFlags = ["--ssh"];
      };
      environment.systemPackages = with pkgs; [
        tailscale
      ];

      networking.firewall = {
        checkReversePath = "loose"; # See https://carlosvaz.com/posts/setting-up-headscale-on-nixos/
        trustedInterfaces = [ config.services.tailscale.interfaceName  ]; # allow all traffic from the Tailscale interface
        allowedUDPPorts = [ config.services.tailscale.port ]; # allow the Tailscale UDP port through the firewall
      };
      networking.nftables.enable = true;

      # optimization
      systemd.services.tailscaled.serviceConfig.Environment = [ "TS_DEBUG_FIREWALL_MODE=nftables" ];
    
      systemd.network.wait-online.enable = false; 
      boot.initrd.systemd.network.wait-online.enable = false;
    };
    darwin = { pkgs, ... }: {
      # 1. Enable the Tailscale daemon
      # Note: nix-darwin's tailscale module has no authKeyFile/extraUpFlags.
      # Auth + `--ssh` flags are handled via the macOS Tailscale GUI app.
      services.tailscale ={
        enable = true;
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
}