{ den, ... }:
{

# meta-config for all users
den.schema.user = { lib,...}: {
    classes = lib.mkDefault [ "homeManager" ];
};

# boreal desktop host
den.hosts.x86_64-linux.boreal= {
    users.avanonyme = {};

    microvm.guests = [den.hosts.x86_64-linux.igloo];

   users.gamer = {}; #gaming user
 };

# cool host server
den.hosts.x86_64-linux.cool = {
   users.avanonyme = { };
 };

# arctic Macos — tailscale client only, no microvm guests (macOS can't host NixOS VMs)
den.hosts.aarch64-darwin.arctic = { 
   users.avanonyme = {};

};

#vm host
den.hosts.x86_64-linux.igloo = {
   users.avanonyme = { };
   intoAttr = [];
 };
 #vm package
den.hosts.x86_64-linux.igloo-runner = {
   intoAttr = ["microvms" "igloo-runner"];  # not nixosConfigurations — this is a runnable package
   };
    
den.hosts.x86_64-linux.igloo.users.tux = { }; #default user
den.hosts.x86_64-linux.igloo.users.avanonyme = {}; #admin
den.hosts.x86_64-linux.igloo-runner.users.avanonyme = {}; #admin

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
