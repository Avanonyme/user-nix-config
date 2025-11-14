{config, pkgs, ...}:

let 
 myAliases = { 
   ll = "ls -l";
   ".." = "cd ..";
   nrs = "nixos-rebuild switch"; # --flake .#hostname
 };
in
{
  programs.bash.enable = true;
  programs.bash.shellAliases = myAliases;
  programs.zsh = {
   enable = true;
   shellAliases = myAliases;
   envExtra = "export PS1=`%{$(tput setaf 47)%}%n%{$(tput setaf 156)%}@%{$(tput setaf 227)%}%m %{$(tput setaf 231)%}%1~ %{$(tput sgr0)%}$`";
  };
}
