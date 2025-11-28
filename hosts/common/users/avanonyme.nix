{
  config,
  pkgs,
  inputs,
  outputs,
  ...

}:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.avanonyme = {
    isNormalUser = true;
    description = "avanonyme";
    extraGroups = [
    "networkmanager" 
    "wheel"
    "flatpak"
    "audio"
    "video"
    ];
    packages = [inputs.home-manager.packages.${pkgs.system}.default];
# initialHashedPassword
# openssh.authroizedKeys.keys = [];
    home-manager.users.avanonyme = 
     import avanonyme/${config.networking.hostName}.nix;
  };


}
