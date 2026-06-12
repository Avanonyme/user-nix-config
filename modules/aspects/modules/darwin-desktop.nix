{ den, ... }:
{
  den.aspects.darwin-desktop = {

    darwin = { pkgs, ... }: {
        homebrew.casks = [
          "ghostty"

        ];
        homebrew.brews = [ 
          "node" 
          "python"
        ];
        homebrew.taps = [
          "PeachlifeAB/tap"
        ]; #github repo

    };

  };
}
