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

      den.aspects.desktop.noctalia
      den.aspects.apps.gaming
      den.aspects.apps.zen-browser

    ];
    nixos = { ... }: {
      users.users.${username} = {
        initialPassword = ""; # or use hashedPassword
      };
      # /data access is handled by disk/filesystem.nix: the pool root is
      # 0775 group users, and normal users (incl. gamer) are in that group.
      # The old recursive `chown -R gamer /data && chmod -R 777` unit was
      # dropped — it silently merged with two other fix-data-perms units,
      # was O(library size) on every boot, and made everything world-writable.
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
