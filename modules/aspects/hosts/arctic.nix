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

      # Create /etc/zshrc that loads the nix-darwin environment.
      # this is required if you want to use darwin's default shell - zsh
      programs.zsh.enable = true;
    };
    homeManager =
    { pkgs, ... }:
    {
    
    };
  };
}
