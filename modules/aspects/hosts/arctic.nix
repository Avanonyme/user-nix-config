# darwin
{den, inputs, __findFile, ...}:
{
  den.aspects.arctic = {
     includes = [ 
      <core/darwin>
      <core/dev-laptop>
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
