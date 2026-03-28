{ inputs, den, ... }:
{
  
  imports = [ 
  (inputs.den.namespace "vm" false)
  (inputs.den.namespace "core" false)

  ];

  # this line enables den angle brackets syntax in modules.
  _module.args.__findFile = den.lib.__findFile;
}
