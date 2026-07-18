{ den, ... }:
{
  den.aspects.desktop.darwin-desktop = {
    includes = [
      den.aspects.hardware.darwin #hardware/
    ];

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
