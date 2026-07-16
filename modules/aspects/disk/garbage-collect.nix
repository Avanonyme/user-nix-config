{den,...}:{
  den.aspects.disk.gc.nixos = {
    boot.loader.grub.configurationLimit = 10;
    nix.gc = {
      automatic = true;
      dates = "*-*-* 21:00:00";
      options = "--delete-older-than 7d";
    };
  };
}