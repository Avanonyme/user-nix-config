{ den, ... }:
{
  den.aspects.darwin-desktop = {

    darwin = { pkgs, ... }: {

      services.aerospace = {
        enable = true;
        settings = builtins.fromTOML (builtins.readFile ../.configs/aerospace.toml);
      };

      services.sketchybar = {
        enable = true;
        package = pkgs.sketchybar;
        extraPackages = [ pkgs.jq pkgs.sketchybar-app-font ];
        config = builtins.readFile ../.configs/sketchybarrc;
      };

      # hide native menu bar so sketchybar has the full strip
      system.defaults.NSGlobalDomain._HIHideMenuBar = true;

    };

  };
}
