# darwin
{den, inputs, __findFile, ...}:
{
  den.aspects.arctic = {
     includes = [ 
      <core/darwin>
      <core/dev-laptop>
    ];


    darwin =
    { pkgs, ... }:
    {
 
    };
    homeManager =
    { pkgs, ... }:
    {
    };
  };
}
