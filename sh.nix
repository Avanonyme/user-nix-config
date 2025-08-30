{config, pkgs, ...}:

let 
 myAliases = { 
   ll = "ls -l";
   ".." = "cd ..";
 };
in
{
  programs.bash.enable = true;
  programs.bash.shellAliases = myAliases;
  programs.zsh = {
   enable = true;
   shellAliases = myAliases;
  };
}
