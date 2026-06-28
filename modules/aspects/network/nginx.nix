{ den, lib, ... }:
# followed https://bkiran.com/blog/using-nginx-in-nixos
# subdomain example is used in headscale.nix
{
  den.aspects.networking.nginx = {
    settings = {
      basedomain = lib.mkOption {
        type = lib.types.str;
        description = "Your domain name";
      };
    };

    nixos = { host, ... }: let
      domain = host.settings.networking.nginx.basedomain;
    in {
      services.nginx = {
        enable = true;

        default = {
          serverName = "_";
          default = true;
          rejectSSL = true;
          locations."/".return = "444";
        };
        virtualHosts."${domain}" = {
          serverName = domain;
          useACMEHost = domain;
          acmeroot = "/var/lib/acme/challenges-${domain}";
          forceSSL = true;
          addSSL = true;
          enableACME = true;
          # no default location — services add their own
        };
      };
      security.acme = {
        acceptTerms = true;
        defaults.email = "avanix26@protonmail.com";

        certs."${domain}" = {
          webroot = "/var/lib/acme/challenges-${domain}";
          email = "avanix26@protonmail.com";
          group = "nginx";
        };
      };
      networking.firewall.allowedTCPPorts = [
        80 #HTTP
        443 #HTTPs
      ];

      users.users.nginx.extraGroups = [ "acme" ];
    };
  };
}
