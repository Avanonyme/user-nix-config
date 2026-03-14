{
  vix.networking.nixos =
    { lib, pkgs, ... }:
    {
      networking.networkmanager.enable = true;
      networking.useDHCP = lib.mkDefault true;

      #enable tailscale
      networking.firewall.enable = true; # Ensure firewall is enabled
      networking.firewall.allowedUDPPorts = [ 41641 ];
      networking.trustedInterfaces = [ "tailscale0" ]; # Or add "tailscale0" to your existing list
      environment.systemPackages = with pkgs; [
      	tailscale
      ];
      services.tailscale.enable = true;
    };
}
