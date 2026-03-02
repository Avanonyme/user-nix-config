# darwin
{den, inputs, __findFile, ...}:
{
  den.aspects.arctic = {
     includes = [ 
      <vix/darwin>
      <vix/dev-laptop>
    ];


    nixos =
    { pkgs, ... }:
    {
 
    };
    homeManager =
    { pkgs, ... }:
    {
    };
  };
}
