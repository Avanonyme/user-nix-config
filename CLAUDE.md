# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

NixOS/nix-darwin dotfiles managed with [den](https://github.com/vic/den), a declarative system manager built on flake-parts. It manages three hosts: `boreal` (x86_64-linux desktop), `arctic` (aarch64-darwin), and `igloo` (x86_64-linux VM).

## Key commands

```bash
# Validate flake structure and check for errors
nix flake check

# Update a specific flake input (e.g. den, nixpkgs)
nix flake update den

# Regenerate flake.nix from modules (never edit flake.nix directly)
nix run .#write-flake

# Apply NixOS config on the local host
sudo nixos-rebuild switch --flake .#localhost

# Apply Home Manager config only
home-manager switch --flake .
```
**Important**: those commands will only be used by the user.

**Important**: `flake.nix` is auto-generated. Flake inputs are declared per aspects

## Architecture

### Framework stack
- **den**: host/user/aspect composition system
- **flake-file** + **import-tree**: auto-discovers and imports all `.nix` files under `modules/`
- **flake-parts**: underlying flake module system

### Central config files
- `modules/den.nix` — declares hosts, users, and which aspects each uses
- `modules/dendritic.nix` — needed flake inputs for dendritic design configuration in den; see https://not-a-number.io/2025/refactoring-my-infrastructure-as-code-configurations/#flipping-the-configuration-matrix
- `modules/aspects/defaults.nix` — global state versions and auto-included aspects

### Aspect pattern

Everything is an *aspect* — a composable config unit. Every module file exports:

```nix
{den, inputs, pkgs, ...}: {
  den.aspects.my-feature = {
    includes = [ <other/aspect> ];          # aspect dependencies

    nixos = { config, lib, pkgs, host, ... }: {
      # NixOS (system-level) config
    };

    homeManager = { pkgs, user, lib, ... }: {
      # Home Manager (user-level) config
    };
  };
}
```

Aspects are referenced with angle-bracket paths (`<core/networking>`, `<vm/routes>`) which resolve via `modules/namespace.nix`. A host or user lists its `includes` in `den.nix`; den assembles the final system config from those.

### Directory layout under `modules/aspects/`

| Directory | Purpose |
|-----------|---------|
| `core/`   | Reusable system aspects (networking, sound, bluetooth, openssh, etc.) |
| `hosts/`  | Per-host declarations (hardware, boot, filesystem) |
| `users/`  | Per-user declarations (packages, desktop, git config) |
| `modules/`| Feature modules (noctalia-desktop, niri, gaming, gpu, sops, disko-config) |
| `vm/`     | VM-specific overrides (autologin, CI boot suppression) |

### Host → user wiring (den.nix)

```nix
den.hosts.x86_64-linux.boreal.users.avanonyme = {};
den.hosts.x86_64-linux.boreal.users.tux = {};
```

The aspect for each host is in `aspects/hosts/<hostname>.nix`; for each user in `aspects/users/<username>.nix`.

### Desktop stack

- **Noctalia** — GNOME-like shell configured via `noctalia-desktop.nix`
- **Niri** — Wayland compositor, KDL config, keybindings in `aspects/modules/niri.nix`
- **GDM** with Wayland enabled on boreal

### Secrets

`sops-nix` is wired in `aspects/modules/sops.nix` but not yet fully deployed. Secrets files are not committed.

### TODO

 - Deploy Secrets with sops-nix
 - Deploy new install with nixos-anywhere and disko-config.nix