# Avanonyme — Nix Configuration

Personal NixOS/darwin flake using the [Den framework](https://den.denful.dev/).

## Hosts

| Host   | Role         | Arch               |
|--------|-------------|---------------------|
| arctic | Darwin laptop | aarch64-darwin     |
| boreal | Workstation   | x86_64-linux       |
| cool   | Server        | x86_64-linux       |

## Structure

```
modules/
├── aspects/
│   ├── core/           # base (hostname, openssh)
│   ├── network/        # nginx, headscale, base
│   ├── disk/           # disko partition layouts
│   ├── desktop/        # niri, noctalia, stylix
│   ├── hardware/       # GPU, darwin
│   ├── services/       # vaultwarden, media-server
│   ├── virtualization/ # microvm, podman
│   ├── secrets/        # sops-nix
│   ├── users/          # per-user configs
│   ├── hosts/          # per-host configs
│   ├── apps/           # gaming, AI, zen-browser
│   └── devshell/     
├── den.nix              # host/user declarations
├── namespace.nix        # angle-bracket paths
└── dendritic.nix
```

## Workflows

### Deploy to a host

```console
# Build on the remote host itself, deploy from here 
nixos-rebuild switch --flake .#cool \
  --build-host root@<host-ip> \
  --target-host root@<host-ip>
```
or from macos with wheel

```console
nix run nixpkgs#nixos-rebuild -- switch --flake .#cool \
  --build-host avanonyme@<host-ip> \
  --target-host avanonyme@<host-ip> \
  --use-remote-sudo
  --ask-elevate-password
```

or directly from the host
```console
sudo nixos-rebuild switch --flake github.com:Avanonyme/user-nix-config#host
```
### Fresh install with nixos-anywhere

```console
nix run github:nix-community/nixos-anywhere -- \
  --flake .#cool \
  root@<host-ip>
```

### Update Den

```console
nix flake update den
nix run .#write-flake
nix flake check
```

### Run microvm host

```console
sudo systemctl start microvm@igloo.service
```
or just run the pkg:

```console
nix run .#igloo-runner
```

## Inspiration

- https://github.com/sini/nix-config
- https://github.com/denful/den
