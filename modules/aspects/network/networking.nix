{
  # networking.domain = rustedbonghomeserver.mooo.com ?
  den.aspects.networking.base= {
    nixos =
    { lib, pkgs, config,... }:

    {
      networking.networkmanager.enable = true;
      networking.useDHCP = lib.mkDefault false;

      networking.firewall = {
        # enable the firewall
        enable = true;

      };
    };
    darwin = { pkgs, config, ... }: {
      # Note: macOS doesn't use 'trustedInterfaces' or 'allowedUDPPorts'
      networking.applicationFirewall = {
        enable = true;
        allowSigned = true;
        allowSignedApp = true;
      };
    };
  };

# host-to-internet port forwarding
  den.aspects.port_forward = {port,address,...}:{
    networking.nat = {
      enable = true;
      forwardPorts = [ {
        proto = "tcp";
        sourcePort = port;
        destination = address; #my-addresses.https-reverse-proxy.ip4;
      } ];
    };
  };

}
