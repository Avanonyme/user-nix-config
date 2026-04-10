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
