# Avanonyme — Nix Configuration

Personal NixOS/darwin flake using the [Den framework](https://den.denful.dev/).

## Hosts

| Host   | Role         | Arch               |
|--------|-------------|---------------------|
| arctic | Darwin laptop | aarch64-darwin     |
| boreal | Workstation   | x86_64-linux       |
| cool   | Server        | x86_64-linux       |

MicroVM guests of cool: sealskin (headscale, 10.0.83.6), qimmit (agents, 10.0.83.7).

## Structure

```
modules/
├── aspects/
│   ├── core/           # base (hostname, openssh, define-user)
│   ├── networking/     # nginx, headscale, tailscale, base
│   ├── disk/           # disko partition layouts
│   ├── desktop/        # niri, noctalia, stylix, darwin-desktop
│   ├── hardware/       # GPU, darwin (mac-app-util, determinate)
│   ├── services/       # vaultwarden, media-server, nextcloud
│   ├── virtualization/ # microvm, podman
│   │   └── microvms/   # guest defs
│   ├── security/       # sops-nix, polkit
│   ├── users/          # per-user configs
│   ├── hosts/          # per-host configs
│   ├── apps/           # fish, ghostty, hyprwhispr, obsidian, zen-browser, ai
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

### MicroVMs

Guests run declaratively under a metal host via `microvm.guests` in `den.nix`.
Networking: host bridge `microbr` (10.0.83.1/24, guest gateway) + NAT out
`enp1s0`, provided by the `virtualization.microvm-bridge` aspect on the metal host.

**Full option reference for building a new guest (router / exit node):**
[modules/aspects/virtualization/microvms/microvm-networking.md](modules/aspects/virtualization/microvms/microvm-networking.md)

```console
# start a declared guest on the metal host
sudo systemctl start microvm@sealskin.service

# or run a standalone runner pkg
nix run .#igloo-runner
```

## Inspiration

- https://github.com/sini/nix-config
- https://github.com/denful/den
