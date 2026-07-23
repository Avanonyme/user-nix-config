# MicroVM Networking Reference — igloo base & host bridge/NAT

Reference for building a new microVM (e.g. a **router** or **exit node**) on this
flake. Documents every option in `igloo.nix` (guest base aspect) and the
route/bridge/NAT in `../microvm.nix` (host side), plus the host-side wiring in
`sealskin.nix` that you'll need to mirror for port forwarding.

Sources: `igloo.nix`, `../microvm.nix`, `sealskin.nix`, `qimmit.nix`,
`../../../den.nix`, [microvm.nix networking docs](https://microvm-nix.github.io/microvm.nix/advanced-network.html).

---

## 1. Topology (current state)

```
                 upstream Internet
                       │
                  enp1s0            ← host (metal) external interface, hardcoded
                       │              in microvm.nix NAT + sealskin forwardPorts
              ┌────────┴────────┐
              │  networking.nat │      host masquerades microbr → enp1s0
              └────────┬────────┘
                  microbr  10.0.83.1/24   ← host bridge (gateway for all guests)
                 ╱    ╲
        microvm6      microvm7            ← tap devices, enslaved to microbr
            │            │
      10.0.83.6     10.0.83.7             ← guests (sealskin, qimmit)
       (sealskin:    (qimmit: AI agents,
        headscale,    workspace share)
        80/443 fwd
        from host)
```

- Guest default gateway: `10.0.83.1` (hardcoded route in igloo's systemd-networkd config).
- Guest DNS: `8.8.8.8`, `1.1.1.1` (hardcoded in igloo).
- Guest firewall: **disabled** (`networking.firewall.enable = false`) — guests rely on host NAT for isolation. If your router/exit-node guest accepts forwarded ports or tailnet traffic, reconsider this.
- Subnet in use: `10.0.83.0/24`. Host takes `.1`; guests take `.6+` by convention (no DHCP — static per-guest assignment via aspect parameters).

### Address allocation (keep updated)

| IP         | tap       | MAC                 | Guest     | Role                  |
|------------|-----------|---------------------|-----------|-----------------------|
| 10.0.83.1  | microbr   | —                   | (host)    | bridge / gateway / NAT |
| 10.0.83.6  | microvm6  | 02:00:00:00:00:06   | sealskin  | headscale server      |
| 10.0.83.7  | microvm7  | 02:00:00:00:00:07   | qimmit    | agent workloads       |

---

## 2. Host side — `virtualization.microvm-bridge` (`../microvm.nix`)

Include `den.aspects.virtualization.microvm-bridge` in the **metal host** aspect
(e.g. `cool.nix`). Creates the bridge, attaches guest tap devices, and NATs the
subnet out the external interface. NixOS class only.

```nix
den.aspects.virtualization.microvm-bridge.nixos = { ... }: {
  systemd.network.enable = true;

  systemd.network.netdevs."10-microbr".netdevConfig = {
    Kind = "bridge";
    Name = "microbr";
  };

  systemd.network.networks."10-microbr" = {
    matchConfig.Name = "microbr";
    addresses = [ { Address = "10.0.83.1/24"; } ];
    networkConfig.ConfigureWithoutCarrier = true;
  };

  systemd.network.networks."11-microvm-tap" = {
    matchConfig.Name = "microvm*";
    networkConfig.Bridge = "microbr";
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "microbr" ];
    externalInterface = "enp1s0";
  };
};
```

### Option-by-option

| Option | Value | Why it matters for a router/exit node |
|---|---|---|
| `systemd.network.enable` | `true` | networkd manages the bridge + taps. Required — igloo guests also use networkd inside. |
| `netdevs."10-microbr".netdevConfig.Kind` | `"bridge"` | Creates L2 bridge netdev `microbr`. All guest taps are enslaved here; guests share one L2 segment. |
| `netdevs."10-microbr".netdevConfig.Name` | `"microbr"` | Stable name; referenced by `matchConfig` below and by `networking.nat.internalInterfaces`. |
| `networks."10-microbr".matchConfig.Name` | `"microbr"` | Applies the address to the bridge itself. |
| `networks."10-microbr".addresses` | `10.0.83.1/24` | Host's address on the guest segment — **this is the guest default gateway** (igloo hardcodes `Gateway = "10.0.83.1"`). If you change it, change igloo's route too. |
| `networks."10-microbr".networkConfig.ConfigureWithoutCarrier` | `true` | Bridge gets its address even with no taps attached (before any guest boots). Keeps the gateway reachable for early-boot guests. |
| `networks."11-microvm-tap".matchConfig.Name` | `"microvm*"` | Glob matching guest tap interface names. **Your guest's `tapID` must start with `microvm`** or the tap won't join the bridge (igloo passes `tapID` straight to `microvm.interfaces[].id`). |
| `networks."11-microvm-tap".networkConfig.Bridge` | `"microbr"` | Enslaves each matching tap to the bridge at L2. |
| `networking.nat.enable` | `true` | Enables `ip_forward` on the host (`boot.kernel.sysctl."net.ipv4.ip_forward" = 1`) and sets up masquerading. |
| `networking.nat.internalInterfaces` | `[ "microbr" ]` | Source NAT (masquerade) for traffic leaving the bridge; guests reach the Internet with the host's external IP. |
| `networking.nat.externalInterface` | `"enp1s0"` | **Hardcoded.** Change to the metal host's real upstream interface (`ip link` on the metal host). Wrong value = guests lose Internet silently. |

### What `networking.nat` does *not* give you

- No inbound forwarding — that's `networking.nat.forwardPorts` (see §5, sealskin pattern).
- No forwarding *between* guests restrictions — guests on `microbr` can reach each other directly at L2 with no host firewall in the path. A compromised guest can reach all siblings. For a router VM this is usually what you want; for untrusted guests, add bridge-level filtering (`networking.nftables`/`firewall` on the host, `bridge` family).
- No IPv6 NAT — the setup is IPv4-only. Guests get no v6 (igloo sets `networking.tempAddresses = "disabled"`).

---

## 3. Guest base — `den.aspects.microvms.igloo` (`igloo.nix`)

Parametric aspect — call it with the guest's identity. Both existing guests use it:

```nix
(microvms.igloo {
  ipAddress = "10.0.83.7";
  mac       = "02:00:00:00:00:07";
  tapID     = "microvm7";
  workspace = "/home/users/qimmit";
})
```

### Parameters

| Param | Used in | Constraints |
|---|---|---|
| `ipAddress` | `systemd.network.networks."10-e".addresses` → `${ipAddress}/24` | Static, unique on `10.0.83.0/24`. Prefix is hardcoded `/24` — if you ever change the subnet size you must edit igloo. |
| `mac` | `microvm.interfaces[].mac` | Locally-administered MACs (`02:00:...` range). Must be unique per guest or taps will flap. |
| `tapID` | `microvm.interfaces[].id` | **Must match `microvm*`** to be picked up by the host's `"11-microvm-tap"` networkd rule (§2). Must be unique on the host (it's the host-side interface name, ≤15 chars). |
| `workspace` | `microvm.shares[]` (source + mountPoint) | Host path virtiofs-shared into the guest at the same path. sealskin uses `/srv/sealskin` (service data), qimmit uses `/home/users/qimmit` (user data). For a router/exit node you may not need one, but the parameter is mandatory — pass a real host path. |

### Guest NixOS options (all inside the aspect's `nixos` class)

#### Boot / storage model

| Option | Value | Notes |
|---|---|---|
| `imports` | `[ inputs.microvm.nixosModules.microvm ]` | The microvm.nix guest module. |
| `system.stateVersion` | `den.default.nixos.system.stateVersion` | Inherited from flake defaults. |
| `fileSystems."/".device` / `.fsType` | `tmpfs` | **Ephemeral root** — everything outside mounted volumes/shares vanishes on reboot. Persistent state must live under `/var` (the `var.img` volume, §4) or the workspace share. For an exit node: Tailscale state (`/var/lib/tailscale`) survives via `var.img`. |
| `systemd.tmpfiles.settings."fix-root-perms"."/".z` | mode `0755` root:root | tmpfs mounts `0700`-ish by default; relaxes `/` so sshd/user sessions work. |
| `systemd.settings.Manager.DefaultTimeoutStopSec` | `"5s"` | Fast VM shutdown/reboot. |
| `systemd.mounts` (store drop-in) | `/nix/store`, `DefaultDependencies=false` | Workaround for microvm.nix issue #170 shutdown deadlock (umount binary lives in the store being unmounted). Keep. |

#### Networking (guest-internal)

| Option | Value | Notes |
|---|---|---|
| `services.resolved.enable` | `true` | systemd-resolved for DNS stub. |
| `networking.useDHCP` | `false` | Fully static. |
| `networking.useNetworkd` / `systemd.network.enable` | `true` | networkd inside the guest too. |
| `networking.tempAddresses` | `"disabled"` | No IPv6 privacy/temp addresses. |
| `systemd.network.networks."10-e".matchConfig.Name` | `"e*"` | Matches the guest-visible NIC. microvm.nix tap interfaces appear in-guest as `enp0s*`/`eth*` style names starting with `e` — catch-all for the single virtio NIC. |
| `..."10-e".addresses` | `${ipAddress}/24` | Static guest IP. |
| `..."10-e".routes` | `[ { Gateway = "10.0.83.1"; } ]` | Default route via the host bridge. **The single route in this setup.** For a router VM you'll add policy routes / a second table for tailnet-originated traffic on top of this. |
| `networking.nameservers` | `8.8.8.8`, `1.1.1.1` | Public resolvers. An exit node serving other tailnet machines should answer DNS itself or forward to the host's resolver — consider `services.resolved` forwarding or running a stub that respects headscale MagicDNS (`100.100.100.100` on the tailnet). |
| `networking.firewall.enable` | `false` | "Behind NAT anyway." For an **exit node**, traffic from the tailnet flows *through* this guest to the Internet/LAN — the host NAT no longer shields it. Re-enable the firewall or add nftables rules limiting what the tailnet may reach (e.g. only masquerade, drop to `10.0.83.0/24` siblings). |

#### SSH

| Option | Value | Notes |
|---|---|---|
| `services.openssh.hostKeys` | `/etc/ssh/host-keys/ssh_host_ed25519_key` (ed25519) | Host keys mounted from outside the VM (see `core.openssh` aspect) so host key identity survives ephemeral root + rebuilds. The commented-out `/var/lib/ssh` block is the alternative (persist on `var.img`). |

#### `microvm.*` block (hypervisor config)

| Option | Value | Notes |
|---|---|---|
| `microvm.hypervisor` | `"qemu"` | Host-side hypervisor for declarative guests. |
| `microvm.vcpu` | `8` | Sized for agent workloads; a pure router/exit node needs 1–2. |
| `microvm.mem` | `4096` (MiB) | Same — exit node fine at 512–1024. |
| `microvm.socket` | `"control.socket"` | Hypervisor control socket (in the guest's state dir on host) — used by `microvm -c` / shutdown commands. |
| `microvm.writableStoreOverlay` | `"/nix/.rw-store"` | tmpfs overlay over the shared read-only `/nix/store`; **required for `nix-daemon` and home-manager activation inside the guest**. |
| `microvm.interfaces` | `[ { type = "tap"; id = tapID; mac = mac; } ]` | The single NIC. `type = "tap"` = host creates tap `tapID`, enslaved to `microbr` by the §2 glob. (The darwin runner variant in igloo uses `type = "user"` = QEMU user-mode NAT — different beast, only for standalone runners.) |
| `microvm.volumes` | `[ { mountPoint = "/var"; image = "var.img"; size = 8192; } ]` | Persistent ext4 image (MiB) in the guest's state dir on the host, mounted at `/var`. **All durable guest state lives here.** |
| `microvm.shares` | virtiofs `workspace` → `workspace` | Host path bind-shared into the guest. `proto = "virtiofs"` needs the virtiofsd daemon (host side handled by microvm.nix). |
| `microvm.credentialFiles` | (commented template) | systemd credentials: host injects files into `/run/host-credentials/` in the guest. This is the sops age-key delivery mechanism (see sealskin's working version in §5). |

#### Secrets plumbing (commented template in igloo; sealskin shows it live)

1. `age-keygen -o <guest>_age.key`
2. Add the pubkey to `.sops.yaml` as a new key group for the guest.
3. `sops updatekeys secrets/secrets.yaml` to grant the guest decrypt rights.
4. On the **metal host**, store the age key as a sops secret (e.g. `microvm/<guest>_key`) and reference it via `microvm.credentialFiles."sops-age-key"`.
5. In the **guest**: `sops.age.keyFile = "/run/host-credentials/sops-age-key"`.

---

## 4. Declaring the guest and attaching it to a host

Two halves — the guest host declaration, and the metal host attachment.

### Guest declaration (`den.nix` pattern)

```nix
den.hosts.x86_64-linux.myrouter = {
  intoAttr = [];                    # no nixosConfigurations output — it's a guest
  users.avanonyme = { includes = [ den.aspects.avanonyme.headless ]; };
  users.tux = {};
};
```

The guest's aspect (e.g. `den.aspects.myrouter`) includes `(microvms.igloo { ... })` plus whatever role aspects (`networking.headscale.client`, etc.).

### Metal host attachment

```nix
# in the metal host's den.nix entry:
microvm.guests = [ den.hosts.x86_64-linux.myrouter ];
```

plus the metal host aspect including:

```nix
den.aspects.virtualization.microvm-bridge   # bridge + NAT (§2)
den.aspects.virtualization.microvms.myrouter # host-side per-VM bits (§5)
```

Run/debug on the metal host: `systemctl start microvm@myrouter.service`,
console via `microvm -c myrouter` (socket from `microvm.socket`).

---

## 5. Host-side per-VM options — the sealskin pattern (`sealskin.nix`)

`den.aspects.virtualization.microvms.sealskin` is the template for metal-host
config tied to one guest:

```nix
nixos = { host, ... }: {
  microvm.vms."sealskin".autostart = true;   # boot with the host

  networking.nat = {
    enable = true;
    externalInterface = "enp1s0";            # must match microvm-bridge
    forwardPorts = [
      { proto = "tcp"; sourcePort = 80;  destination = "10.0.83.6:80"; }
      { proto = "tcp"; sourcePort = 443; destination = "10.0.83.6:443"; }
    ];
  };
};
```

| Option | Meaning |
|---|---|
| `microvm.vms."<name>".autostart` | Declarative microvm.nix host option; starts `microvm@<name>.service` at boot. cool.nix relies on this + a daily 05:00 reboot timer to recover stuck VMs. |
| `networking.nat.forwardPorts` | Host-level DNAT: external `sourcePort` → guest `destination`. This is how sealskin's headscale gets public 80/443. **For a router/exit node you generally don't forward ports to it** — instead the guest forwards/masquerades *outbound* for the tailnet. |

Note the `networking.nat` attrset merges with the one in `microvm-bridge` (same module system) — `internalInterfaces` from the bridge aspect and `forwardPorts` here compose into one NAT ruleset.

sealskin's **guest-side** sops wiring (the live version of igloo's commented template):

```nix
microvm.credentialFiles."sops-age-key" = "/run/secrets/microvm/sealskin_key"; # host path
sops.age.keyFile      = lib.mkForce "/run/host-credentials/sops-age-key";      # guest path
sops.defaultSopsFile  = lib.mkForce ../../../../secrets/secrets.yaml;
sops.secrets."headscale/auth_key" = {};
```

`lib.mkForce` because the values override what the `security.sops` aspect already sets.

---

## 6. Checklist — turning an igloo-based guest into a router / exit node

Guest side (your new aspect, on top of `microvms.igloo`):

1. **IP forwarding** — igloo doesn't set it; add
   `boot.kernel.sysctl."net.ipv4.ip_forward" = true;` (and `net.ipv6.conf.all.forwarding` if v6).
2. **Tailscale/headscale exit node** — include `networking.headscale.client`,
   then `tailscale up --advertise-exit-node` (or `services.tailscale.extraUpFlags = [ "--advertise-exit-node" ];`),
   and approve the exit-node route in the headscale ACL/web UI on sealskin.
3. **Masquerade tailnet→world** — `networking.nat.enable = true; networking.nat.externalInterface = "e*";`
   won't accept a glob; set it to the concrete guest NIC name (check with `networkctl` after first boot — igloo's match rule is `e*`, typically `enp0s3`-style). Internal interface: `tailscale0`.
4. **Firewall** — igloo disables it; for an exit node re-enable and only allow
   established/related + tailscale0 input, forward from tailscale0 only.
5. **DNS** — replace igloo's hardcoded `8.8.8.8/1.1.1.1` with what the tailnet should resolve (headscale MagicDNS or a resolver you control), since tailnet clients will use this node's DNS when it's their exit node.
6. **Subnet routing (optional)** — to make the guest a *subnet router* for
   `10.0.83.0/24` or the metal LAN, `tailscale up --advertise-routes=10.0.83.0/24,...`
   and approve routes in headscale. L2 reachability to siblings is already there via `microbr`.
7. **Secrets** — follow §3 secrets plumbing with your own `<guest>_age.key` if the guest needs a tailscale auth key from sops (see sealskin's `headscale/auth_key` pattern).
8. **Host side** — include `virtualization.microvm-bridge` (once per metal host) and your
   `virtualization.microvms.<guest>` aspect (autostart; *skip* `forwardPorts` unless you also
   terminate public services there). Verify `externalInterface = "enp1s0"` matches the metal host.
9. **Sizing** — drop `vcpu`/`mem` (override after the igloo include: `microvm.vcpu = lib.mkForce 2;` etc.).
10. **MTU** — virtio tap defaults (1500) are fine for guest↔host; tailscale0 will be 1280. If you advertise subnet routes, tailscale handles the encapsulation overhead; no bridge MTU changes needed.

### Files to touch

- new: `modules/aspects/virtualization/microvms/<guest>.nix` (guest aspect + host-side aspect, mirroring `sealskin.nix`)
- edit: `modules/den.nix` (guest host declaration + `microvm.guests` on the metal host)
- edit: metal host aspect includes (`modules/aspects/hosts/cool.nix` pattern)
- maybe edit: `igloo.nix` only if you need a different prefix length, nameservers, or non-`e*` match rule — prefer per-guest overrides via `lib.mkForce` in your guest aspect instead.
