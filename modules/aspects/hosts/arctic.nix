# darwin
{den, inputs, __findFile, ...}:
{
  den.aspects.arctic = {
     includes = with den.aspects; [
      core.hostname
     # <core/dev-laptop>
      desktop.darwin-desktop
      virtualization.microvm-darwin
      networking.base
      networking.headscale.client
      security.sops
    ];

    # Auto-included into avanonyme's USER scope on this host via the
    # user-aspect-auto-include policy in aspects/defaults.nix.
    # NOTE: homeManager blocks only apply from user-scope includes —
    # putting them in the host includes above silently drops them.
    avanonyme = {
      homeManager.imports = [
        # Trampoline home-manager apps (obsidian, zen-browser, ghostty…)
        # into ~/Applications so Spotlight/Launchpad can find them.
        inputs.mac-app-util.homeManagerModules.default
      ];
    };

    darwin =
    { pkgs, config, ... }:
    {
    #  All the configuration options are documented here:
    #    https://daiderd.com/nix-darwin/manual/index.html#sec-options
    
      system = {
			  primaryUser = "avanonyme";

        defaults = {
          controlcenter.BatteryShowPercentage = true;
          dock.autohide = true;
          hitoolbox.AppleFnUsageType = "Do Nothing";

          finder = {
            AppleShowAllExtensions = true;
            AppleShowAllFiles = true;
            ShowStatusBar = true;
            _FXShowPosixPathInTitle = true;
            _FXSortFoldersFirst = true;
          };
        };
      };
      environment.systemPackages = with pkgs; [
      ];

      # Add ability to used TouchID for sudo authentication
      security.pam.services.sudo_local.touchIdAuth = true;

      # Fish is the default shell — enabled via apps.fish + den.provides.user-shell "fish"
    };
  };
}
