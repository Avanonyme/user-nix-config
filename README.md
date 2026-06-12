# Getting Started Guide

Steps you can follow after cloning this template:

- Be sure to read the [den documentation](https://vic.github.io/den)

- Update den input.

```console
nix flake update den
```

- Run checks to test everything works.

```console
nix flake check
```

- Use `nix run .#write-flake` to regenerate flake.nix

- Edit [modules/hosts.nix](modules/hosts.nix)

Install with nixos-anywhere
nix run github:nix-community/nixos-anywhere \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  -- \
  -i ~/.ssh/id_ed25519 \ #if needed
  --build-on-remote \
  --flake github:Avanonyme/user-nix-config#host \
  root@<host-ip>


to run the vm:
nix build .#nixosConfigurations.boreal.config.system.build.vm
then execute the locally generated QEMU output link:
./result/bin/run-boreal-vm


for guest microvm (igloo on boreal):
sudo systemctl start microvm@igloo.service

to run the runner:
nix run .#igloo-runner

the hypervisor for macos is vfkit