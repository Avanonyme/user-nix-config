{ inputs, pkgs, lib, ... }:
let
  darwin-cfg = {
    # Determinate uses its own daemon to manage the Nix installation
    determinateNix.enable = true;

    system.defaults.trackpad.Clicking = true;
    system.defaults.trackpad.TrackpadThreeFingerDrag = true;
    system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;

    system.keyboard.enableKeyMapping = true;
    system.keyboard.remapCapsLockToControl = true;
  };

  nix-darwin-pkgs =
    { pkgs, ... }:
    {
      imports = [
        inputs.mac-app-util.darwinModules.default
      ];
      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = true;
          cleanup = "uninstall";
          upgrade = true;
        };
      };
      
      environment.systemPackages = with inputs.nix-darwin.packages.${pkgs.system}; [
        darwin-option
        darwin-rebuild
        darwin-version
        darwin-uninstaller
      ];
    };
in
{

  flake-file.inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    nix-darwin.url = "github:LnL7/nix-darwin";
    mac-app-util.url = "github:hraban/mac-app-util";
  };
  # 1st darwin is aspect name; 2nd darwin is host system
  den.aspects.hardware.darwin.darwin.imports = [ 
    inputs.determinate.darwinModules.default
    nix-darwin-pkgs
    darwin-cfg
  ];
}
