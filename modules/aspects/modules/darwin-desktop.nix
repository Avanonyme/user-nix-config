{ den, ... }:
{
  den.aspects.darwin-desktop = {

    darwin = { pkgs, ... }: {
        homebrew.casks = [
          #"hyprspace"#not a cask yet  https://hyprspace.net
          "ghostty"
        ];
        homebrew.brews = [ 
          "node" 
          "python"
        ];
        homebrew.taps = []; #github repo

    };

  };
}
