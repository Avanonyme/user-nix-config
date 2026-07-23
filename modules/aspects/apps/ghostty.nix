{
  # https://ghostty.org/docs/configuration
  den.aspects.apps.ghostty = {
    darwin =
      { pkgs, ... }:
      {
        # Ghostty is installed via homebrew cask in desktop.darwin-desktop
        # This module manages the config file only
      };

    homeManager =
      { pkgs, ... }:
      {
        xdg.configFile."ghostty/config" = {
          text = ''
            # Ghostty configuration
            # https://ghostty.org/docs/configuration

            # Shell
            shell-integration = fish
            command = ${pkgs.fish}/bin/fish

            # Window
            background-opacity = 0.85
            background-blur-radius = 20
            window-padding-x = 8
            window-padding-y = 4
            macos-titlebar-style = tabs
            macos-non-native-fullscreen = true

            # Font
            font-family = "GeistMono Nerd Font"
            font-size = 14

            # Cursor
            cursor-style = bar
            cursor-style-blink = true

            # Theme
            theme = solarized-osaka-night

            # Keybindings — match pi's Ctrl+G for external editor
            keybind = super+d:new_split:right
          '';
        };
      };
  };
}
