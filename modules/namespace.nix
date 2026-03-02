{ inputs, den, ... }:
{
  # create an `vm` (example!) namespace.
  imports = [ (inputs.den.namespace "vm" false)

  # you can have more than one namespace (false = not flake exposed)
  #(inputs.den.namespace "my" false)

  # you can also merge many namespaces from remote flakes.
  # keep in mind a namespace is defined only once, so give it an array:
  #(inputs.den.namespace "ours" [inputs.ours inputs.theirs])
  (inputs.den.namespace "vix" false)

  ];

  # this line enables den angle brackets syntax in modules.
  _module.args.__findFile = den.lib.__findFile;
}
