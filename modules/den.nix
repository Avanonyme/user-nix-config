{

# meta-config for all users
den.schema.user = { lib,...}: {
    classes = lib.mkDefault [ "homeManager" ];
};

# boreal desktop host
den.hosts.x86_64-linux.boreal= {
    users.avanonyme = {};

    users.tux = {};
 }; #gaming user

# arctic Macos
den.hosts.aarch64-darwin.arctic.users.avanonyme = { };

#vm host
den.hosts.x86_64-linux.igloo.users.avanonyme = { };
#den.hosts.aarch64-darwin.igloo.users.avanonyme = { };
}

/*   hm-aspect-deprecated = ''
    NOTICE: den.provides.home-manager aspect is not used anymore.
    See https://den.oeiuwq.com/guides/home-manager/

    Since den.ctx.hm-host requires least one user with homeManager class,
    Home Manager is now enabled via options.

    For all users unless they set a value:

       den.schema.user.classes = lib.mkDefault [ "homeManager" ];

    On specific users:

       den.hosts.x86_64-linux.igloo.users.tux.classes = [ "homeManager" ];

    For attaching aspects to home-manager enabled hosts.
  '';
 */
