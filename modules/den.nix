{den,inputs,...}:
let
   domain = "rustedbonghomeserver.mooo.com";
   admin_email = "avanix26@protonmail.com";
   # other global settings go here
in
{
imports = [
   (inputs.flake-file.flakeModules.dendritic or { })
   (inputs.den.flakeModules.dendritic or { })
];

# other inputs may be defined at a module using them.
flake-file.inputs = { #general inputs
   den.url = "github:denful/den";
   flake-file.url = "github:denful/flake-file";
   
   home-manager = {
   url = "github:nix-community/home-manager";
   inputs.nixpkgs.follows = "nixpkgs";
   };
   darwin = {
   url = "github:nix-darwin/nix-darwin";
   inputs.nixpkgs.follows = "nixpkgs";
   };

   ## these stable inputs are for wsl
   #nixpkgs-stable.url = "github:nixos/nixpkgs/release-25.05";
   #home-manager-stable.url = "github:nix-community/home-manager/release-25.05";
   #home-manager-stable.inputs.nixpkgs.follows = "nixpkgs-stable";

   #nixos-wsl = {
   #  url = "github:nix-community/nixos-wsl";
   #  inputs.nixpkgs.follows = "nixpkgs-stable";
   #  inputs.flake-compat.follows = "";
   
};

# meta-config for all users
den.schema.user = { lib,...}: {
    classes = lib.mkDefault [ "homeManager" ];
};
den.reservedKeys = ["settings"]; #options in aspects; see http://gist.github.com/sini/58bab05ae3d3605de07edba94f7b3c7d

#### HOSTs + USERs ####

# boreal - desktop
den.hosts.x86_64-linux.boreal= {
   users.avanonyme = {};
   users.gamer = {}; #gaming user

   microvm.guests = [den.hosts.x86_64-linux.igloo]; #vm host; systemctl start microvm@igloo

   #settings.networking.headscale.login_server ="head.${domain_name}";
 };

# cool - server
den.hosts.x86_64-linux.cool = {
   users.avanonyme = {   };
   microvm.guests = [den.hosts.x86_64-linux.igloo];

   settings = {
      cool.domain = domain;
      cool.admin_email = admin_email;
   };
 };

# arctic- laptop
den.hosts.aarch64-darwin.arctic = { 
   users.avanonyme = {
      classes = [ ]; #no homemanager on darwin

   };

};

}

