{ den, ... }:
let
  description = ''
    Sets user as *guest*.

    On NixOS adds the user as a normal user without elevated privileges.

    ## Usage

       den.aspects.my-user.includes = [ den._.guest-user ];

  '';

  userToHostContext =
    { user, ... }:
    {
      inherit description;
      nixos.users.users.${user.userName} = {
        isNormalUser = true;
      };
    };

in
{
  den.provides.guest-user = den.lib.take.exactly userToHostContext;
}
