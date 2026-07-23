{...}:{
  # TODO if noctalia aspect; also enable noctwhspr plugin
  den.aspects.apps.hyprwhispr = {
    nixos = { config, user, lib, pkgs, ... }:{
      # Allow the user to intercept keyboard shortcuts natively
      users.users.${user.userName}.extraGroups = [ "input" ];

      # Enable the built-in systemd service
      services.hyprwhspr-rs.enable = true;

      # Override the package based on GPU drivers
      services.hyprwhspr-rs.package = 
          pkgs.hyprwhspr-rs.override {
            whisper-cpp = pkgs.whisper-cpp.override { rocmSupport = true; };
          };

      # Add the client package to your system profile
      environment.systemPackages = [ 
        config.services.hyprwhspr-rs.package # Inherit the GPU-accelerated package version
        pkgs.whisper-cpp
      ];
    };

    homeManager =
      { config, ... }:
      {
        xdg.configFile."hyprwhspr-rs/config.jsonc" = {
          text = ''
            {
              "shortcuts": {
                "press": "SUPER+ALT+D",
                "hold": "SUPER+ALT+CTRL"
              },
              "audio_feedback": true,
              "start_sound_volume": 0.1,
              "stop_sound_volume": 0.1,
              "auto_copy_clipboard": true,
              "shift_paste": false,
              "transcription": {
                "provider": "whisper_cpp",
                "request_timeout_secs": 45,
                "max_retries": 2,
                "whisper_cpp": {
                  "model": "large-v3-turbo-q8_0",
                  "gpu_layers": 999
                }
              }
            }
          '';
        };
      };
    darwin =
      { pkgs, ... }:
      {
        # hyperwhisper is a native macOS dictation app — different from hyprwhspr-rs
        homebrew.casks = [
          "open-wispr"
        ];

        # Ensure whisper-cli is available on PATH for apps that use it
        homebrew.brews = [
          "whisper-cpp"
        ];
      };
  };
}
