{den,...}:{
# DDNS setup for a server without a router

den.aspects.networking.ddclient = {
  settings ={lib,...}: {
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Full freedns.afraid.org domain";
    };
  };
  nixos = {host,config,...}:{
    services.ddclient = {
      enable = true;
      quiet=true;
      interval = "5min";
      protocol = "freedns";
      use="web, web=myip.dnsomatic.com";
      server = "freedns.afraid.org";
      ssl = true;
      username = "RustedBong";
      passwordFile = config.sops.secrets."ddclient/password".path;

      domains = ["${host.settings.networking.ddclient.domain}"];
    };
  };
};

# References:
# https://wiki.nixos.org/wiki/Ddclient
# https://ddclient.net/protocols.html
# https://gist.github.com/h3r3/1e21e376256855bd3a30

}