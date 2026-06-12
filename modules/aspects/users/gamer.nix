{ den, ... }:
# gaming user
  let 
    username = "gamer";
  in
{
  # user aspect
  den.aspects.${username} = {
    includes = [
      den.provides.define-user
      (den.provides.user-shell "fish")

      den.aspects.noctalia-desktop
      den.aspects.gaming
      den.aspects.zen-browser

    ];
    nixos = { ... }: {
      users.users.${username} = {
        initialPassword = ""; # or use hashedPassword
      };
                  #allow boreal's users to own /mnt/data
      systemd.services.fix-data-perms = {
        wantedBy = [ "multi-user.target" ];
        after = [ "zfs-mount.service" "data.mount" ];
        serviceConfig.Type = "oneshot";
        script = "chown -R ${username} /mnt/data && chmod -R 777 /mnt/data";
      };
    };
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ 
          htop
          ghostty
          vscodium
          discord
        ];


      };

  };
}
