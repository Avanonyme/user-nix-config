{ core, ... }:
{
  core.dev-laptop = {
    includes = [
      core.networking
      core.bluetooth
      core.sound
      core.xserver
      #core.hw-detect
      core.macos-keys
    ];
    nixos = {
      security.rtkit.enable = true;
      powerManagement.enable = true;
    };
    darwin =
    { pkgs, ... }:
    {
      powerManagement.enable = true;
    };
  };
}
