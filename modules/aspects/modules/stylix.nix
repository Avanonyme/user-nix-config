{ den, inputs, ... }:{
  den.aspects.stylix = {
    nixos = { pkgs, lib, ... }: {
      imports = [
        inputs.stylix.nixosModules.stylix
        # stylix expects services.kmscon.config which doesn't exist in this nixpkgs
        { options.services.kmscon.config = lib.mkOption {
            type = lib.types.attrsOf lib.types.raw;
            default = {};
          };
        }
      ];

      stylix = {
        enable = true;
        polarity = "dark";
        image = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/danth/stylix/main/testing/test-wallpaper.jpg";
          hash = "sha256-Va5tT8xtb+X6tZ1oHn5Bf2E38Oax7KaoW24Hn1g1h9w=";
        };
        cursor = {
          name = "Bibata-Modern-Ice";
          package = pkgs.bibata-cursors;
          size = 24;
        };
        fonts = {
          serif = {
            package = pkgs.nerd-fonts.geist-mono;
            name = "Geist Mono Nerd Font";
          };
          sansSerif = {
            package = pkgs.nerd-fonts.geist-mono;
            name = "Geist Mono Nerd Font";
          };
          monospace = {
            package = pkgs.nerd-fonts.geist-mono;
            name = "Geist Mono Nerd Font";
          };
          sizes = {
            applications = 12;
            desktop = 10;
            popups = 12;
            terminal = 14;
          };
        };
      };
    };
  };
}
