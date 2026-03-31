{
  core.openssh.nixos ={
    # Enable the OpenSSH daemon.
    services.openssh = {
      enable = true;
      settings.PermitRootLogin = "no";
      #settings.PasswordAuthentication = false; #not needed for avanonyme user
      allowSFTP = true;
    };
  };
}
