{ den, config, ... }:
# base user
  let 
    username = "tux";
  in
{
  # user aspect
  den.aspects.${username}.headless = {
    includes = [
      den.provides.define-user
      (den.provides.user-shell "fish")


    ];
    nixos = { ... }: {

    };
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ 
          htop
          ghostty
        ];


      };
  };
}
