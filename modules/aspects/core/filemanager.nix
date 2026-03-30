{
  core.filemanager = {
    nixos = 
    {pkgs, ...}:
    {

      environment.systemPackages = with pkgs; [
        #filesystem manager #move to its own aspect
        nautilus
        gvfs        # virtual filesystem (USB, MTP, SMB, etc.)
        udiskie     # auto-mounts drives on plug-in
      ];
            #enable automounting 
      services.devmon.enable = true;
      services.gvfs.enable = true;
      services.udisks2.enable = true;
      
    };

    homeManager = {
            #move to filesystem aspcct
      services.udiskie = { 
        enable = true;
        automount = true;
        notify = true;   # sends a dunst notification on plug (you already have dunst)
      };
    };
  };
}
