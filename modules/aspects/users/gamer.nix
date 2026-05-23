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
    };
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ 
          htop
          ghostty
          vscodium
        ];


      };

    # user can provide NixOS configurations
    # to any host it is included on
    # nixos = { pkgs, ... }: { };
  };
}
