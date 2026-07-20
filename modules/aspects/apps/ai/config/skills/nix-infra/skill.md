---
name: nix-infra
description: NixOS infrastructure knowledge for the Avanonyme homelab — Den framework, flakes, aspects, microVMs, and deployment conventions.
---

# NixOS Infrastructure Knowledge (Avanonyme Homelab)

## Host Topology

Three hosts across two architectures:

| Host | OS | Role | IP |
|------|-----|------|----|
| boreal | NixOS x86_64 | Desktop (niri, AMD GPU, gaming) | Tailnet + LAN |
| cool | NixOS x86_64 | Server (nginx, NAT, remote builder) | 192.168.50.2 + Tailnet |
| arctic | nix-darwin aarch64 | Laptop | Tailnet |

MicroVMs on cool:
- **sealskin** (10.0.83.6) — Headscale tailnet controller
- **qimmit** (10.0.83.7) — AI agent host (planned)

## Den Framework Conventions

Config lives in `~/.dotfiles/` using the Den framework (`github:denful/den`).

### Structure
```
modules/
├── den.nix         # Host/user/microvm declarations, global settings
├── namespace.nix   # Angle-bracket paths (e.g. <networking/nginx>)
├── aspects/
│   ├── hosts/      # Per-host config
│   ├── users/      # Per-user config
│   ├── networking/ # nginx, headscale, tailscale, ddclient
│   ├── core/       # hostname, openssh, define-user
│   ├── disk/       # disko partition layouts
│   ├── desktop/    # niri, noctalia, stylix
│   ├── hardware/   # GPU (amd/nvidia), darwin
│   ├── services/   # media-server, vaultwarden, nextcloud
│   ├── security/   # sops-nix secrets
│   ├── apps/       # gaming, AI, zen-browser, obsidian
│   └── test/       # experimental (ipfs-media)
├── schema/         # Option type schemas for aspects
├── quirks/         # Den framework overrides
└── policies/       # Include policies
```

### Aspect Composition Pattern
```nix
den.aspects.myFeature = {
  includes = with den.aspects; [
    core.openssh
    security.sops
  ];
  nixos = { pkgs, config, ... }: { /* NixOS config */ };
  darwin = { pkgs, config, ... }: { /* nix-darwin config */ };
  homeManager = { pkgs, ... }: { /* home-manager config */ };
};
```

### Host Declaration (den.nix)
```nix
den.hosts.x86_64-linux.boreal = {
  users.avanonyme = { aspect = den.aspects.avanonyme.desktop; };
  settings.networking.domain = "rustedbonghomeserver.mooo.com";
};
```

### Deployment
```bash
# From any machine with flakes
nixos-rebuild switch --flake ~/.dotfiles#cool \
  --build-host root@<host> --target-host root@<host>

# Or locally
sudo nixos-rebuild switch --flake ~/.dotfiles#boreal
```

### Secrets (sops-nix)
Encrypted with age keys, stored in `secrets/secrets.yaml`. Decrypted at build time via `config.sops.secrets."<name>".path`.

### MicroVMs
- Defined as Den hosts with `intoAttr = [];` (no standalone nixosConfiguration)
- Bridge network on 10.0.83.0/24 via `microvm-bridge` aspect
- Port forwarding on metal host for public services

## Important Paths & Domains
- Domain: `rustedbonghomeserver.mooo.com` (FreeDNS DDNS)
- Tailnet domain: `tnet.loc` (Headscale MagicDNS)
- Admin email: `avanix26@protonmail.com`
- Secrets: `~/.dotfiles/secrets/secrets.yaml`
