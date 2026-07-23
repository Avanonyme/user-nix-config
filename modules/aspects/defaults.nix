{
  config,
  # deadnix: skip # enable <den/brackets> syntax for demo.
  __findFile ? __findFile,
  den,
  pkgs,
  lib,
  ...
}:
{
  # Lets also configure some defaults using aspects.
  # These are global static settings.
  den.default = {
    darwin.system.stateVersion = 6;
    nixos.system.stateVersion = "25.05";
    homeManager.home.stateVersion = "25.05";

    includes = [
      den.batteries.define-user
      den.batteries.hostname
    ];

  };

    # Default user includes — per-user data emission + entity-named aspect auto-include
  den.schema.user.includes = [
    #emits resolved-users entry 
    den.aspects.resolved-user-emitter

    # Include den.aspects.<hostname>.<username> if it exists
    # DISABLED: Den core's host-to-users policy already auto-includes host sub-aspects
    # matching user names. Keeping both causes double-application, which errors on any
    # sub-aspect importing a foreign module (duplicate option declarations).
    # (den.lib.policy.mkPolicy "user-aspect-auto-include" (
    #   { host, user, ... }:
    #   lib.optional (den.aspects ? ${host.name} && den.aspects.${host.name} ? ${user.name}) (
    #     den.lib.policy.include den.aspects.${host.name}.${user.name}
    #   )
    # ))
  ];

}
