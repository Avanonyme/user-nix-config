# Router for cool subnet + tailnet exit node
{den,inputs,pkgs,...}:
let
  ipadd="10.0.83.1";
in
{
  #used by microvm guest host
  den.aspects.beacon ={config, ...}:{ 
    includes = with den.aspects;[
      security.sops

      (microvms.igloo{
        ipAddress = "${ipadd}"; 
        mac ="02:00:00:00:00:01" ;
        tapID = "microvm1"; 
        workspace = "/srv/beacon"; # should be in user home
      })
    ];
  };
}
