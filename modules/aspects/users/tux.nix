{ den, ... }:
# gaming user
{
  # user aspect
  den.aspects.tux = {
    includes = [
      den._.guest-user
      (den.provides.user-shell "fish")
      den.aspects.gaming

    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ 
          pkgs.htop 
        ];
      };

    # user can provide NixOS configurations
    # to any host it is included on
    # nixos = { pkgs, ... }: { };
  };
}
