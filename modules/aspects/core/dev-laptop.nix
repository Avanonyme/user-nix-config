{ core, ... }:
{
  core.dev-laptop = {
    includes = [
      core.bluetooth
      core.sound
      core.xserver
      core.macos-keys
    ];
    nixos = {
      security.rtkit.enable = true;
      powerManagement.enable = true;
    };
  };
}
