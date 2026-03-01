{den , ...}:
{
 den.aspects.avanonyme = {
    includes = [
      den.provides.primary-user
      (den.provides.user-shell "zsh")
      den.aspects.noctalia-desktop
      
    ];

    homeManager =
      { pkgs, user, ... }:
      {
        home.packages = [ pkgs.htop ];
      };

    # user can provide NixOS configurations
    # to any host it is included on
    # nixos = { pkgs, ... }: { };
  };

}
