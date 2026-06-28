{ den, config, inputs, lib, ... }:

let
  secretsDir = ../../../secrets;
  secretFile = secretsDir + "/secrets.yaml";
in
{
  den.aspects.kanidm = {
    settings = {
        kanidmDomain = lib.mkOption {
          type = lib.types.str;
          description = "Your domain name";
        };
        kanidmPort = lib.mkOption {
          type = lib.types.str;
          default = 8085;
          description = "Port opened for headscale ( default 8085 )";
        };
    };
    includes = [ den.aspects.nginx ];

    nixos = { host, config, pkgs, lib, ... }:
    let
      domain = host.settings.domain;
      kanidmDomain = host.settings.security.kanidm.kanidmDomain;
      kanidmPort = host.settings.security.kanidm.kanidmPort;

    in
    {
      services.kanidm = {
        package = pkgs.kanidm;  # bump to kanidm_1_10 if available in your nixpkgs

        server = {
          enable = true;
          settings = {
            domain = kanidmDomain;
            origin = "https://${kanidmDomain}";
            bindaddress = "127.0.0.1:8443";
            # kanidm speaks HTTPS natively, nginx terminates TLS and proxies
          };
        };

        client = {
          enable = true;
          settings.uri = "https://${kanidmDomain}";
        };

        provision = {
          enable = true;
          adminPasswordFile = config.sops.secrets."kanidm/admin_password".path;
          idmAdminPasswordFile = config.sops.secrets."kanidm/admin_password".path;

          groups."vpn.users" = {
            members = [ "avanonyme" ];
          };

          persons."avanonyme" = {
            displayName = "avanonyme";
            mailAddresses = [ "you@${domain}" ];
            groups = [ "vpn.users" ];
          };
        };
      };

      services.nginx.virtualHosts.${kanidmDomain} = {
        forceSSL = true;
        enableACME = true;
        useACMEHost = domain;
        locations."/" = {
          # kanidm speaks https internally — nginx must proxy over https
          proxyPass = "https://127.0.0.1:8443";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_ssl_verify off;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
          '';
        };
      };

      # kanidm needs to read its TLS cert and the sops secret files
      systemd.services.kanidm.serviceConfig.SupplementaryGroups = [ "keys" ];

      security.acme.certs.${domain}.extraDomainNames = [ kanidmDomain ];
    };
  };
}