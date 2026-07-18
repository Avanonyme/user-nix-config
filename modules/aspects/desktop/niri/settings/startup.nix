{ inputs, ... }:
{
  den.aspects.desktop.niri-startup = {
    imports = [ inputs.niri-nix.homeModules.default ];

    homeManager = {
      wayland.windowManager.niri.settings = {
        hotkey-overlay.skip-at-startup = true;

        spawn-at-startup = [
          {_args = [ "noctalia" ];}
          {_args = ["systemctl" "--user" "start" "graphical-session.target"];}
        ];
      };
    };
  };
}