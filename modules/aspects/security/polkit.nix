{den,...}:{
  den.aspects.security.polkit.nixos = {host, pkgs,...}: {
    security.polkit.enable = true;
    security.rtkit.enable = true;
    environment.systemPackages = with pkgs; [
      polkit_gnome      # GUI Standard/stable auth agent
      # Alternatively, you could use libsForQt5.polkit-kde-agent
    ];

    #https://wiki.nixos.org/wiki/Polkit
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

  };
}