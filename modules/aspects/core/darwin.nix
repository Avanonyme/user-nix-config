{ inputs, ... }:
let

  flake-file.inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    nix-darwin.url = "github:LnL7/nix-darwin";
    mac-app-util.url = "github:hraban/mac-app-util";
  };

  core.darwin.darwin.imports = [ #core is namespace; 1st darwin is aspect name; 2nd darwin is host system
    inputs.determinate.darwinModules.default
    nix-darwin-pkgs
    darwin-cfg
  ];

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
  # TODO: link home-manager apps.
in
{
  inherit core flake-file;
}
