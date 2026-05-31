{den,...}:{

# meta-config for all users
den.schema.user = { lib,...}: {
    classes = lib.mkDefault [ "homeManager" ];
};

# boreal desktop host
den.hosts.x86_64-linux.boreal= {
    users.avanonyme = {};

    users.gamer = {}; #gaming user

    microvm.guests = [den.hosts.x86_64-linux.igloo];
 }; 

# arctic Macos
den.hosts.aarch64-darwin.arctic.users.avanonyme = { };

#vm host
den.hosts.x86_64-linux.igloo = {
   users.avanonyme = { };
   intoAttr = [];  # dont produce Guest nixosConfiguration at flake output
 };
#den.hosts.aarch64-darwin.igloo.users.avanonyme = { };

den.hosts.x86_64-linux.runnable-microvm = {
    intoAttr = [
        "microvms"
        "runnable-microvm"
    ]; # pkgs; not intended to be used from nixosConfigurations
};
}

