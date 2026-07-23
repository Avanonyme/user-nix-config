/**
 * Infrastructure topology viewer.
 *
 * Commands:
 *   /infra              Full static topology and local observations
 *   /infra hosts        Hosts
 *   /infra services     Services declared for this host; local status if supported
 *   /infra microvms     MicroVM inventory
 *   /infra networks     Networks
 *
 * Agent tools:
 *   infra_topology      Full topology plus local observations
 *   infra_service_status  Query one local systemd service (Linux only)
 */

import { execFileSync } from "node:child_process";
import { hostname, platform } from "node:os";
import { Type } from "typebox";
import type {
  ExtensionAPI,
  ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";

type Host = {
  name: string;
  role: string;
  os: string;
  ip: string;
  services: string[];
};

type MicroVM = {
  name: string;
  ip: string;
  role: string;
  metal: string;
  autostart: boolean;
};

type Network = {
  name: string;
  type: string;
  controller?: string;
  subnet?: string;
  metal?: string;
  entry?: string;
  ddns?: string;
};

const TOPOLOGY: {
  hosts: Host[];
  microvms: MicroVM[];
  networks: Network[];
} = {
  hosts: [
    {
      name: "boreal",
      role: "desktop",
      os: "NixOS x86_64",
      ip: "tailnet",
      services: [
        "pi-coding-agent",
        "kubo",
        "headscale-client",
        "niri",
        "noctalia",
      ],
    },
    {
      name: "cool",
      role: "server",
      os: "NixOS x86_64",
      ip: "192.168.50.2 + tailnet",
      services: [
        "nginx",
        "ddclient",
        "nat-forward",
        "microvm-host",
      ],
    },
    {
      name: "arctic",
      role: "laptop",
      os: "nix-darwin aarch64",
      ip: "tailnet",
      services: [
        "hermes-container",
        "ollama",
        "headscale-client",
      ],
    },
  ],

  microvms: [
    {
      name: "sealskin",
      ip: "10.0.83.6",
      role: "Headscale server",
      metal: "cool",
      autostart: true,
    },
    {
      name: "qimmit",
      ip: "10.0.83.7",
      role: "AI agents (planned)",
      metal: "cool",
      autostart: false,
    },
  ],

  networks: [
    {
      name: "tailnet",
      type: "WireGuard",
      controller: "sealskin (10.0.83.6)",
    },
    {
      name: "microvm-bridge",
      type: "bridge",
      subnet: "10.0.83.0/24",
      metal: "cool",
    },
    {
      name: "public",
      type: "internet",
      entry: "cool -> sealskin:80/443 (NAT)",
      ddns: "rustedbonghomeserver.mooo.com",
    },
  ],
};

type ServiceObservation =
  | { supported: true; service: string; running: boolean }
  | { supported: false; service: string; reason: string };

function isLinux(): boolean {
  return platform() === "linux";
}

function systemdStatus(service: string): ServiceObservation {
  if (!isLinux()) {
    return {
      supported: false,
      service,
      reason: `Local service status unavailable on ${platform()}: systemd is Linux-only`,
    };
  }

  try {
    execFileSync(
      "systemctl",
      ["is-active", "--quiet", service],
      {
        stdio: "ignore",
        timeout: 3000,
      },
    );

    return { supported: true, service, running: true };
  } catch {
    return { supported: true, service, running: false };
  }
}

function localHost(): Host | undefined {
  return TOPOLOGY.hosts.find((host) => host.name === hostname());
}

function localObservations() {
  const host = localHost();

  return {
    hostname: hostname(),
    platform: platform(),
    topologyHost: host?.name ?? null,
    serviceStatusSupported: isLinux(),
    services: host
      ? host.services.map(systemdStatus)
      : [],
  };
}

function statusGlyph(observation: ServiceObservation): string {
  if (!observation.supported) return "?";
  return observation.running ? "●" : "○";
}

function renderHosts(): string {
  const me = hostname();

  return TOPOLOGY.hosts
    .map((host) => {
      const marker = host.name === me ? "★" : "•";
      return `${marker} ${host.name}  ${host.role}  [${host.os}]  ${host.ip}`;
    })
    .join("\n");
}

function renderNetworks(): string {
  return TOPOLOGY.networks
    .map((network) => {
      const detail =
        network.controller ??
        network.entry ??
        network.subnet ??
        "No detail";

      const extras = [
        network.metal && `metal: ${network.metal}`,
        network.ddns && `ddns: ${network.ddns}`,
      ]
        .filter(Boolean)
        .join("; ");

      return `🌐 ${network.name}  (${network.type})\n   ${detail}${
        extras ? `\n   ${extras}` : ""
      }`;
    })
    .join("\n");
}

function renderMicroVMs(): string {
  return TOPOLOGY.microvms
    .map((vm) => {
      const state = vm.autostart ? "● autostart" : "○ manual";
      return `${state}  ${vm.name}  ${vm.ip}  (${vm.role})  on ${vm.metal}`;
    })
    .join("\n");
}

function renderServices(): string {
  const host = localHost();

  if (!host) {
    return [
      `Local hostname: ${hostname()}`,
      "No matching host exists in the static topology.",
      "No local service inventory is available.",
    ].join("\n");
  }

  const lines = [
    `Services declared for ${host.name}`,
    `Status backend: ${isLinux() ? "systemd" : `unavailable (${platform()})`}`,
    "",
  ];

  for (const observation of host.services.map(systemdStatus)) {
    if (observation.supported) {
      lines.push(
        `${statusGlyph(observation)} ${observation.service}  ${
          observation.running ? "active" : "inactive/unknown"
        }`,
      );
    } else {
      lines.push(`? ${observation.service}  ${observation.reason}`);
    }
  }

  return lines.join("\n");
}

function renderTopology(): string {
  return [
    `Infrastructure topology (seen from ${hostname()} on ${platform()})`,
    "════════════════════════════════════════════════════════",
    "",
    "── Networks ──",
    renderNetworks(),
    "",
    "── Hosts ──",
    renderHosts(),
    "",
    "── Local services ──",
    renderServices(),
    "",
    "── MicroVMs ──",
    renderMicroVMs(),
  ].join("\n");
}

const SERVICE_STATUS_PARAMS = Type.Object({
  service: Type.String({
    minLength: 1,
    description: "Local systemd unit name, e.g. nginx.service",
  }),
});

export default function infrastructureTopologyExtension(
  pi: ExtensionAPI,
) {
  pi.registerCommand("infra", {
    description:
      "Show infrastructure topology. Usage: /infra [hosts|services|microvms|networks]",
    handler: async (args: string, ctx: ExtensionCommandContext) => {
      const subcommand = args.trim().toLowerCase();

      const output = (() => {
        switch (subcommand) {
          case "":
            return renderTopology();

          case "hosts":
            return renderHosts();

          case "services":
            return renderServices();

          case "microvms":
            return renderMicroVMs();

          case "networks":
            return renderNetworks();

          default:
            return [
              `Unknown infra view: ${subcommand}`,
              "Usage: /infra [hosts|services|microvms|networks]",
            ].join("\n");
        }
      })();

      ctx.ui.notify(output, "info");
    },
  });

  pi.registerTool({
    name: "infra_topology",
    label: "Infrastructure Topology",
    description:
      "Return the static homelab inventory and local runtime observations. Host, network, and MicroVM data are declarative inventory, not live remote discovery.",
    parameters: Type.Object({}),
    async execute() {
      const result = {
        topology: TOPOLOGY,
        localObservations: localObservations(),
      };

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(result, null, 2),
          },
        ],
        details: result,
      };
    },
  });

  pi.registerTool({
    name: "infra_service_status",
    label: "Local Service Status",
    description:
      "Check whether a named local systemd unit is active. Only supported on Linux hosts using systemd; it does not perform remote checks.",
    parameters: SERVICE_STATUS_PARAMS,
    async execute(_toolCallId, params) {
      const result = systemdStatus(params.service);

      const text = result.supported
        ? `${result.service}: ${result.running ? "active" : "inactive or unknown"}`
        : `${result.service}: ${result.reason}`;

      return {
        content: [{ type: "text", text }],
        details: result,
      };
    },
  });
}