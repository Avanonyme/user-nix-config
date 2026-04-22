{
  core.networking.nixos =
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
}
