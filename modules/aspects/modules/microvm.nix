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

  #MicroVM runnable aspect; for running as packages
  #
  #See https://den.denful.dev/tutorials/microvm/
  #And https://microvm-nix.github.io/microvm.nix/packages.html
  den.aspects.runnable-microvm = {inputs, ...}:{

    nixos = {

      imports = [ inputs.microvm.nixosModules.microvm ];

      users.users.root.password = "";

      # There's not much need to have a forwarding microvm class for runnable vms
      microvm = {

        volumes = [
          {
            mountPoint = "/var";
            image = "var.img";
            size = 256;
          }
        ];

        shares = [
          {
            # use proto = "virtiofs" for MicroVMs that are started by systemd
            proto = "9p";
            tag = "ro-store";
            # a host's /nix/store will be picked up so that no
            # squashfs/erofs will be built for it.
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
          }
        ];

        # "qemu" has 9p built-in!
        hypervisor = "qemu";
        socket = "control.socket";
        
      };
    };
  };
}