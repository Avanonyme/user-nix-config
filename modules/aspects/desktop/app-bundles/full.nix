{den, ... }:
{
  den.aspects.desktop.full = {
    includes = with den.aspects;[
    #  bitwarden
    
    #  proton
    #  sunshine
      networking.headscale.client
      apps.zen-browser
    ];

    nixos =
      { pkgs, user, ... }:
      {
        users.users.${user.userName}.packages = with pkgs; [
          # https://apps.gnome.org/
          baobab
          eyedropper
          gnome-calculator
          gnome-characters
          gnome-disk-utility
          gnome-font-viewer
          gnome-logs
          gnome-text-editor
          impression
          loupe
          papers

          discord
          discord-canary
          discord-ptb
          element-desktop
          cider-2
          firefox
          obsidian
          qbittorrent
          libreoffice-qt
          hunspell
          signal-desktop
          thunderbird
          veracrypt
          vesktop
          vlc
          zoom-us
        ];
      };

    darwin = {
      homebrew = {
        casks = [
          "alt-tab"
          "discord"
          "element"
          "iina"
          "obs"
          "obsidian"
          "qbittorrent"
          "stats"
          "veracrypt"
          "zoom"
        ];

        masApps = {
          # "Affinity Designer 2" = 1616831348;
          # "Affinity Photo 2: Image Editor" = 1616822987;
          # "Affinity Publisher 2" = 1606941598;
          "Hidden Bar" = 1452453066;
        };
      };
    };
  };
}