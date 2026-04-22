{ den, ... }:
{
  den.aspects.darwin-desktop = {
    darwin = { pkgs, lib, ... }: {

      services.aerospace = {
        enable = true;
        settings = builtins.fromTOML (builtins.readFile ../.configs/aerospace.toml);
      };

      services.sketchybar = {
        enable = true;
        package = pkgs.sketchybar;
        # sketchybar runs your config as a script — point it at a file
        extraPackages = [ pkgs.jq pkgs.sketchybar-app-font ];
        config = builtins.readFile ./../.configs/sketchybarrc;
      };
      # disable default menu bar
      system.defaults.NSGlobalDomain._HIHideMenuBar = true;

    };
  };
}
