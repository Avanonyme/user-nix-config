{den, ... }:
{
  den.aspects.app-bundles.full = {
    includes = with den.aspects;[
    #  bitwarden
    
    #  proton
    #  sunshine
      app-bundles.ai
      apps.zen-browser
      apps.obsidian
      apps.gaming
    ];

    nixos =
      { pkgs, user, ... }:
      #these packages will eventually be moved to their own bundles
      {
                      nixpkgs.config.permittedInsecurePackages = [
                "electron-40.10.5"
              ];
        users.users.${user.userName}.packages = with pkgs; [
          bat #moder replacemement for cat
					htop #resources monitoring

					gh #github in the terminal
					ghostty
					#davinci-resolve #video editing 
					neovim
					fastfetch #sys info

					synergy #same keyboard for local network
					tldr
					unzip
					tree #directory visualisation
					vscodium #code editors

					feh #image viewer
					qemu #virtualization
					gimp #image editing
					vlc #media player

					#fonts
					geist-font 
					nerd-fonts.geist-mono

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
          qbittorrent
          libreoffice-qt
          hunspell
          signal-desktop
          thunderbird
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
          "qbittorrent"
          "stats"
          "zoom"

          "vlc" 
          "gimp"
          "vscodium"
          "bitwarden"
          "signal"
          "transmission"
          "mullvad-vpn"
          "brave-browser"
        ];
        brews = [
				"calibre"
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