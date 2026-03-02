{den, ...}: {
  #services.tailscale = {
  #  enable = true;
  #  useRoutingFeatures = "both";
#
#    authKeyFile = den.aspects.sops.secrets.tailscale_key.path;
#  };
#  #TODO: still need to configure auth key (secrets.yaml)
#
#  sops.secrets.tailscale_key.sopsFile = ../secrets/secrets.yaml;
}
