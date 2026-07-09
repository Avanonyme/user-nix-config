{ den, lib, ... }:
# followed https://bkiran.com/blog/using-nginx-in-nixos
# subdomain example is used in headscale.nix
{
  den.aspects.networking.nginx = {
    nixos = { host, ... }: let
      domain = host.settings.networking.domain;
    in {
      services.nginx = {
        enable = true;

        virutalHosts."default" = { #or default?
          serverName = "_";
          default = true;
          rejectSSL = true;
          locations."/".return = "444";
        };
        virtualHosts."${domain}" = {
          serverName = domain;
          #useACMEHost = domain;
          #acmeRoot = "/var/lib/acme/challenges-${domain}";
          forceSSL = true;
          enableACME = true;
          # no default location — services add their own
        };
      };
      security.acme = {
        acceptTerms = true;
        defaults.email = host.settings.networking.admin_email;

        certs."${domain}" = {
          webroot = "/var/lib/acme/challenges-${domain}";
          email = host.settings.networking.admin_email;
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
