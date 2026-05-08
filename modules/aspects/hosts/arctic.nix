# darwin
{den, inputs, __findFile, ...}:
{
  den.aspects.arctic = {
     includes = [
      <core/hostname>
      <core/networking>
      <core/darwin>
      <core/dev-laptop>
      den.aspects.darwin-desktop
      #den.aspects.darwin-filesystems #in disko-config.nix
    ];


    darwin =
    { pkgs, config, ... }:
    {
      system = {
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
        iterm2
      ];
    };
    homeManager =
    { pkgs, ... }:
    {
    
    };
  };
}
