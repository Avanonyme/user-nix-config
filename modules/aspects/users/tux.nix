{ den, config, ... }:
# base user
  let 
    username = "tux";
  in
{
  # user aspect
  den.aspects.${username} = {
    includes = [
      den.provides.define-user
      (den.provides.user-shell "fish")


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
        ];


      };
  };
}
