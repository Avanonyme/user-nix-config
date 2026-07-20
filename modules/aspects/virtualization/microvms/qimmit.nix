# man's best friend
# AI agents running on a tailnet
{den,inputs,pkgs,...}:
let
  ipadd="10.0.83.7";
in
{
  #used by microvm guest host
  den.aspects.qimmit ={config, ...}:{ 
    includes = with den.aspects;[
      security.sops

      (microvms.igloo{
        ipAddress = "${ipadd}"; 
        mac ="02:00:00:00:00:07" ;
        tapID = "microvm7"; 
        workspace = "/home/share/qimmit"; # should be in user home
      })
    ];
  };
}
