{den,...}:{
  den.aspects.disk.gc = {
    boot.loader.grub.configurationLimit = 10;
    nix.gc = {
      automatic = true;
      dates = "*-*-* 21:00:00";
      options = "--delete-older-than 7d";
    };
  };
}