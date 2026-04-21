{ den, ... }:
# gaming user
{
  # user aspect
  den.aspects.gamer = {
    includes = [
      den.provides.define-user
      (den.provides.user-shell "fish")
      den.aspects.gaming

    ];
    nixos = { ... }: {
      users.users.gamer = {
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
