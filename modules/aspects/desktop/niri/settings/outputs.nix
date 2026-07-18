{ inputs, ... }:
{
  den.aspects.desktop.niri-outputs = {
    imports = [ inputs.niri-nix.homeModules.default ];

    homeManager = {
      wayland.windowManager.niri.settings.output = [
        # VM Testing Monitor
        {
          _args = [ "Virtual-1" ];
          scale = 1.0;
          mode = "1920x1080";
        }
      ];
    };
  };
}