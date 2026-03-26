{
# boreal desktop host
den.hosts.x86_64-linux.boreal.users.avanonyme = { 
    classes = ["homeManager"];
};

den.hosts.x86_64-linux.boreal.users.tux = { 
    classes = ["homeManager"];
}; #gaming user
# arctic laptop
den.hosts.aarch64-darwin.arctic.users.avanonyme = {
    classes = ["homeManager"];
 };

#vm host
den.hosts.x86_64-linux.igloo.users.tux = {
    classes = ["homeManager"];
};
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