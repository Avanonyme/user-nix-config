---
name: infra-review
description: Review the current infrastructure state before making changes.
---

# Infrastructure Review Checklist

Before making infrastructure changes, check:

1. **Which host am I on?** (hostname, tailscale status)
2. **Is the target host reachable?** (tailscale ping)
3. **What's the current config?** (read relevant .nix files in ~/.dotfiles)
4. **Has the flake been checked?** (nix flake check)
5. **Are secrets available?** (sops decrypt check)
6. **Rebuild safely:** use --check first, then switch

Surface the current topology and affected service status before proposing changes.
