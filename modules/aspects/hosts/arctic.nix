# darwin
{den, inputs, __findFile, ...}:
{
  den.aspects.arctic = {
     includes = [
      <core/darwin>
      <core/dev-laptop>
      den.aspects.darwin-desktop
      #den.aspects.darwin-filesystems #in disko-config.nix
    ];


    darwin =
    { pkgs, config, ... }:
    {
      environment.systemPackages = with pkgs; [
        ghostty
      ];
       nix-homebrew = {
          enable = true;
          enableRosetta = true;
          user = "avanonyme";

          taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };
      };
      homebrew.taps = builtins.attrNames config.nix-homebrew.taps; # align homebrew taps with nix-homebrew configuration
    };
    homeManager =
    { pkgs, ... }:
    {
    
    };
  };
}
