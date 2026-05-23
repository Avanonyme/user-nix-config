{ den, ... }:
{
  den.aspects.darwin-desktop = {

    darwin = { pkgs, ... }: {
        homebrew.casks = [
          #"hyprspace"#  https://hyprspace.net, cli: hyprspace init
                     #  for custom config:
                     # $ cp ./.config/hyprspace.toml ~/.config/hyprspace/config.toml
          "ghostty"
          "alfred" #application launcher

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
