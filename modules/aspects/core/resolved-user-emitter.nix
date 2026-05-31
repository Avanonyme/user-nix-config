#Source: https://github.com/sini/nix-config/blob/main/modules/den/aspects/core/resolved-user-emitter.nix#L7
# Emits one resolved-users entry per user at user scope.
# Collected at host scope so host-level aspects can enumerate all users.
{den,...}:{
  den.aspects.resolved-user-emitter = {
    resolved-users =
      { user, ... }:
      {
        inherit (user) name;
        uid = user.system.uid or null;
        inherit (user) groups;
        sshKeys = map (k: k.key) (user.identity.sshKeys or [ ]);
      };
  };
}