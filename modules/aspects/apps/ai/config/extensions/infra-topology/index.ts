/**
 * Infrastructure topology viewer — visualize the full homelab layout:
 * hosts, microVMs, services, network relationships.
 *
 * Commands:
 *   /infra               — full topology tree
 *   /infra hosts         — just the host list
 *   /infra services      — running services
 *   /infra microvms      — microVM status
 *
 * Tools (for agent use):
 *   infra-topology       — full topology as JSON
 *   infra-service-status — check if a service is running
 */

import { execSync } from "node:child_process";
import { hostname } from "node:os";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";

const TOPOLOGY = {
  hosts: [
    {
      name: "boreal",
      role: "desktop",
      os: "NixOS x86_64",
      ip: "tailnet",
      services: ["pi-coding-agent", "kubo", "headscale-client", "niri", "noctalia"],
    },
    {
      name: "cool",
      role: "server",
      os: "NixOS x86_64",
      ip: "192.168.50.2 + tailnet",
      services: ["nginx", "ddclient", "nat-forward", "microvm-host"],
    },
    {
      name: "arctic",
      role: "laptop",
      os: "nix-darwin aarch64",
      ip: "tailnet",
      services: ["hermes-container", "ollama", "headscale-client"],
    },
  ],
  microvms: [
    { name: "sealskin", ip: "10.0.83.6", role: "Headscale server", metal: "cool", autostart: true },
    { name: "qimmit", ip: "10.0.83.7", role: "AI agents (planned)", metal: "cool", autostart: false },
  ],
  networks: [
    { name: "tailnet", type: "WireGuard", controller: "sealskin (10.0.83.6)", domain: "tnet.loc" },
    { name: "microvm-bridge", type: "bridge", subnet: "10.0.83.0/24", metal: "cool" },
    { name: "public", type: "internet", entry: "cool -> sealskin:80/443 (NAT)", ddns: "rustedbonghomeserver.mooo.com" },
  ],
};

function systemdRunning(service: string): boolean {
  try {
    execSync(`systemctl is-active --quiet ${service} 2>/dev/null`, { timeout: 3000 });
    return true;
  } catch {
    return false;
  }
}

function renderTree(): string {
  const lines: string[] = [];
  const me = hostname();
  lines.push(`Infrastructure Topology (seen from ${me})`);
  lines.push("═══════════════════════════════════════");
  lines.push("");

  // Networks
  lines.push("── Networks ──");
  for (const net of TOPOLOGY.networks) {
    lines.push(`  🌐 ${net.name}  (${net.type})`);
    lines.push(`     ${net.controller || net.entry || net.subnet}`);
  }
  lines.push("");

  // Hosts + running services
  lines.push("── Hosts ──");
  for (const h of TOPOLOGY.hosts) {
    const marker = h.name === me ? "★" : "•";
    lines.push(`  ${marker} ${h.name}  [${h.os}]  ${h.ip}`);
    for (const svc of h.services) {
      const running = h.name === "boreal" ? systemdRunning(svc) : false;
      const status = running ? "●" : "○";
      lines.push(`     ${status} ${svc}`);
    }
  }
  lines.push("");

  // MicroVMs
  lines.push("── MicroVMs ──");
  for (const vm of TOPOLOGY.microvms) {
    const status = vm.autostart ? "●" : "○";
    lines.push(`  ${status} ${vm.name}  ${vm.ip}  (${vm.role})  on ${vm.metal}`);
  }

  return lines.join("\n");
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("infra", {
    description: "Display the full homelab topology: hosts, microVMs, services, networks",
    handler: async (args: string, ctx: ExtensionCommandContext) => {
      const sub = args.trim().toLowerCase();

      if (sub === "hosts") {
        return TOPOLOGY.hosts
          .map((h) => `${h.name}  ${h.role}  ${h.os}  ${h.ip}`)
          .join("\n");
      }

      if (sub === "services") {
        const me = hostname();
        const localHost = TOPOLOGY.hosts.find((h) => h.name === me);
        if (!localHost) return "Can't determine local host";
        const results: string[] = [];
        for (const svc of localHost.services) {
          const running = systemdRunning(svc);
          results.push(`${running ? "●" : "○"} ${svc}`);
        }
        return results.join("\n");
      }

      if (sub === "microvms") {
        return TOPOLOGY.microvms
          .map((vm) => `${vm.autostart ? "●" : "○"} ${vm.name}  ${vm.ip}  ${vm.role}`)
          .join("\n");
      }

      return renderTree();
    },
  });

  pi.registerTool("infra-topology", {
    description: "Get the full infrastructure topology as structured data",
    handler: async () => {
      return TOPOLOGY;
    },
  });

  pi.registerTool("service-status", {
    description: "Check if a systemd service is running on the local machine",
    parameters: {
      type: "object",
      properties: {
        service: { type: "string", description: "systemd service name" },
      },
    },
    handler: async (params: Record<string, unknown>) => {
      const svc = params.service as string;
      if (!svc) throw new Error("service is required");
      return { service: svc, running: systemdRunning(svc) };
    },
  });
}
