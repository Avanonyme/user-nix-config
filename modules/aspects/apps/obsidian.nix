{ inputs, ... }:
{
  flake-file.inputs.obsidian-plugins = {
    url = "github:cjavad/nixpille-obsidian-community-plugins";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.apps.obsidian = {
    nixos.nixpkgs.overlays = [
        inputs.obsidian-plugins.overlays.default
      ];
    # home-manager uses the host pkgs (useGlobalPkgs), so darwin hosts
    # need the overlay too or pkgs.obsidianPlugins is missing there
    darwin.nixpkgs.overlays = [
        inputs.obsidian-plugins.overlays.default
      ];
    homeManager = { user, pkgs, ... }: {
      programs.obsidian = {
        enable = true;
        cli.enable = true;
        vaults = {
          "${user.userName}" = {
            enable = false;
            target = "Vault/${user.userName}";
            settings.communityPlugins = with pkgs.obsidianPlugins; [
              obsidian-git
              breadcrumbs
              graph-analysis
            ];
          };

          Agent = {
            enable = false;
            target = "Vault/Agent";
          };
        };
      };
    };
  };
}