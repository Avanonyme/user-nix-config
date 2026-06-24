{den,...}:{

# meta-config for all users
den.schema.user = { lib,...}: {
    classes = lib.mkDefault [ "homeManager" ];
};

# boreal - desktop
den.hosts.x86_64-linux.boreal= {
   users.avanonyme = {};
   users.gamer = {}; #gaming user

   microvm.guests = [den.hosts.x86_64-linux.igloo]; #vm host; systemctl start microvm@igloo

 };

# cool - server
den.hosts.x86_64-linux.cool = {
   users.avanonyme = {   };
 };

# arctic- laptop
den.hosts.aarch64-darwin.arctic = { 
   users.avanonyme = {
      classes = [ ]; #no homemanager on darwin

   };

};

}

