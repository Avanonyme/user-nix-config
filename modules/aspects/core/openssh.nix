{
  den.aspects.core.openssh.nixos ={
    # Enable the OpenSSH daemon.
    services.openssh = {
      enable = true;
      openFirewall = true; #set to false,access through tailscale
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
  };
}
