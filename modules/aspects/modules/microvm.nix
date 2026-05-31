{ den, inputs, lib, config, ... }:
let
  microvmRunners = lib.pipe den.hosts [
    lib.attrValues
    (lib.concatMap lib.attrValues)
    (map (
      host:
      let
        osConf = lib.attrByPath host.intoAttr null config.flake;
        vmRunner = osConf.config.microvm.declaredRunner or null;
        package = lib.optionalAttrs (vmRunner != null) {
          ${host.system}.${host.name} = vmRunner;
        };
      in
      package
    ))
  ];
in
{
  # Declarative Guest VMs on Host (see den.nix for guest and host declaration)
  imports = [
    (import "${inputs.den}/templates/microvm/modules/microvm-integration.nix")
    ];
  # Runnable MicroVM as package
  # for each host exposes microvm declaredRunner (if exists) as package output of this flake.
  config.flake.packages = lib.mkMerge microvmRunners;
}