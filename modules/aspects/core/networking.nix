{
  core.networking.nixos =
    { lib, pkgs, config,... }:
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

        # always allow traffic from your Tailscale network
        trustedInterfaces = [ "tailscale0" ];

        # allow the Tailscale UDP port through the firewall
        allowedUDPPorts = [ config.services.tailscale.port ];

        # let you SSH in over the public internet
        allowedTCPPorts = [ 22 ];
      };

    };
}
