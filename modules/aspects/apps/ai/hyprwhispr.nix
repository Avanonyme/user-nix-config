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
  };
}
