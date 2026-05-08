{
  config,
  # deadnix: skip # enable <den/brackets> syntax for demo.
  __findFile ? __findFile,
  den,
  pkgs,
  ...
}:
{
  # Lets also configure some defaults using aspects.
  # These are global static settings.
  den.default = {
    darwin.system.stateVersion = 6;
    nixos.system.stateVersion = "25.05";
    homeManager.home.stateVersion = "25.05";

  };
  # host<->user provides
  den.ctx.user.includes = [ den.provides.mutual-provider ];
}
