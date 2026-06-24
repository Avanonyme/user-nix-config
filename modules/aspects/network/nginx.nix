{den,...}:
# followed https://bkiran.com/blog/using-nginx-in-nixos
# subdomain example is used in headscale.nix
{
  den.aspects.nginx = {config,...}:
  let
    domain = den.aspects.${config.host.hostName}.domain;
  in
  {
    nginx = {
      enable = true;

      default = {
        serverName = "_";
        default = true;
        rejectSSL = true;
        locations."/".return = "444";
      };
      virtualHosts = {
        "${domain}"={
          serverName = domain;
          useACMEHost = domain;
          acmeroot = "/var/lib/acme/challenges-${domain}";
          forceSSL = true;
          addSSL = true;
          locations."/" = {
            return = "200 \"um...wazzaaaap\"";
          };
        };

      };
    };
    security.acme = {
      acceptTerms = true;
      defaults.email = "avanix26@protonmail.com"; #to derive dynamically

      certs = {
        "${domain}" = {
        webroot = "/var/lib/acme/challenges-${domain}";
        email = "avanix26@protonmail.com"; 
        group = "nginx";
        };

      };
    };
    networking.firewall.allowedTCPPorts = [
      80 #HTTP
      443 #HTTPs
    ];

    users.users.nginx.extraGroups = [ "acme" ];

  };
}