{ den, ... }:
{
  den.aspects.core.dev-laptop = {
    includes = with den.aspects; [
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
