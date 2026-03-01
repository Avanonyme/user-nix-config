# darwin
{den, inputs, ...}:
{
  den.aspects.arctic = {
    nixos =
    { pkgs, ... }:
    {
    include = [ 
      <vix/darwin>
      <vix/dev-laptop>
    ];


    };
    homeManager =
    { pkgs, ... }:
    {
      include = [ 
        <den/noctalia-desktop>
      ];
    };
  };
}
