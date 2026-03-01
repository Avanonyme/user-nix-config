{
  # host aspect
  den.aspects.boreal = { #following den (flake-aspects) convention, flake.aspects.≤aspect≥.≤class≥
    # host NixOS configuration
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ 
          pkgs.hello 
          ];
      };

    # host provides default home environment for its users
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.vim ];
      };
  };
}
