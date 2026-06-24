{
  # networking.domain = rustedbonghomeserver.mooo.com ?
  den.aspects.network.base= {
    nixos =
    { lib, pkgs, config,... }:

    {
      networking.networkmanager.enable = true;
      networking.useDHCP = lib.mkDefault true;

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

}
