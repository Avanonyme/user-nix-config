{ den, inputs, ... }:{

  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix/release-25.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.desktop.stylix = {
    nixos = { pkgs, lib, ... }: {
      imports = [
        inputs.stylix.nixosModules.stylix

      ];

      stylix = {
        enable = true;
        polarity = "dark";
        image = ../../.config/wp8457149-solarpunk-wallpapers.jpg;
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
        targets.qt.enable  = false;
        targets.kmscon.enable = false; 
        targets.gnome.enable = false;
        targets.gtk.enable = false;
      };
    };
     homeManager = { ... }: {

       xdg.configFile."gtk-3.0/gtk.css" = {
         force = true;
       };
       xdg.configFile."gtk-4.0/gtk.css" = {
         force = true;
       };
     };
  };
}
