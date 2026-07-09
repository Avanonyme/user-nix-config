{lib, ...}:{
  # networking.domain = rustedbonghomeserver.mooo.com ?
  den.aspects.networking = {
    settings = {
      domain = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "your domain name";
      };
      admin_email = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "your admin email";
      };
    };

  };
  den.aspects.networking.base= {
    nixos =
    { pkgs, config,... }:

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
}
