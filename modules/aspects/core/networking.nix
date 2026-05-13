{
  # networking.domain = rustedbonghomeserver.mooo.com ?
  core.networking= {
    nixos =
    { lib, pkgs, config,... }:
    # add node to network
    # tailscale up --login-server <headscale_url>
    {
      networking.networkmanager.enable = true;
      networking.useDHCP = lib.mkDefault true;

      services.tailscale.enable =  true;
      environment.systemPackages = with pkgs; [
      	tailscale
      ];

      networking.firewall = {
        # enable the firewall
        enable = true;

        checkReversePath = "loose"; # See https://carlosvaz.com/posts/setting-up-headscale-on-nixos/
        trustedInterfaces = [ "tailscale0" ]; # allow all traffic from the Tailscale interface
        allowedUDPPorts = [ config.services.tailscale.port ];        # allow the Tailscale UDP port through the firewall
        allowedTCPPorts = [ 22 ];  # let you SSH in over the public internet

      };
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

}
