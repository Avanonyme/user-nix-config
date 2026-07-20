/**
 * Tailnet management tools — query Headscale/tailscale status, ping nodes,
 * and inspect the mesh topology.
 *
 * Commands:
 *   /tailnet status           — list all connected nodes
 *   /tailnet ping <host>      — ping a node over the tailnet
 *   /tailnet whoami            — show local tailscale identity
 *
 * Tools (for agent use):
 *   tailnet-status
 *   tailnet-ping
 *   tailnet-whoami
 */

import { execSync } from "node:child_process";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";

function run(cmd: string): string {
  return execSync(cmd, { encoding: "utf-8", timeout: 15_000 });
}

function parseStatus(raw: string): Record<string, unknown>[] {
  const lines = raw.trim().split("\n");
  const nodes: Record<string, unknown>[] = [];

  for (const line of lines) {
    // tailscale status output: <IP> <name> <os> <user> <tags> <online|offline>
    const parts = line.trim().split(/\s+/);
    if (parts.length < 2) continue;
    const [ip, ...rest] = parts;
    const name = rest[0] ?? "?";
    nodes.push({
      ip,
      name,
      online: line.includes("offline") ? false : true,
      raw: line,
    });
  }

  return nodes;
}

export default function (pi: ExtensionAPI) {
  // ── Commands ───────────────────────────────────────────────────────────

  pi.registerCommand("tailnet", {
    description: "Query tailnet status, ping nodes, or inspect identity",
    handler: async (args: string, ctx: ExtensionCommandContext) => {
      const parts = args.trim().split(/\s+/);
      const sub = parts[0]?.toLowerCase();

      switch (sub) {
        case "status":
        case "ls": {
          const raw = run("tailscale status");
          const nodes = parseStatus(raw);
          const online = nodes.filter((n) => n.online).length;
          ctx.ui.notify(`Tailnet: ${online}/${nodes.length} nodes online`, "info");
          return nodes.map((n) => `  ${n.ip}  ${n.name}  ${n.online ? "●" : "○"}`).join("\n");
        }

        case "ping": {
          const target = parts[1];
          if (!target) {
            ctx.ui.notify("Usage: /tailnet ping <hostname|ip>", "error");
            return;
          }
          const raw = run(`tailscale ping --c 3 ${target}`);
          ctx.ui.notify(`Ping results for ${target}`, "info");
          return raw.trim();
        }

        case "whoami":
        case "me": {
          const raw = run("tailscale status --self ");
          const me = parseStatus(raw)[0] ?? { ip: "?", name: "?" };
          ctx.ui.notify(`You are ${me.name} (${me.ip})`, "info");
          return `Identity: ${me.name} @ ${me.ip}`;
        }

        default: {
          ctx.ui.notify("Usage: /tailnet {status|ping <host>|whoami}", "error");
          return;
        }
      }
    },
  });

  // ── Tools ──────────────────────────────────────────────────────────────

  pi.registerTool("tailnet-status", {
    description: "List all nodes on the tailnet with their IPs and online status",
    handler: async () => {
      const raw = run("tailscale status");
      return { nodes: parseStatus(raw), raw };
    },
  });

  pi.registerTool("tailnet-ping", {
    description: "Ping a node over the tailnet to check reachability and latency",
    parameters: {
      type: "object",
      properties: {
        target: { type: "string", description: "Hostname or tailscale IP" },
        count: { type: "number", description: "Number of pings", default: 3 },
      },
    },
    handler: async (params: Record<string, unknown>) => {
      const target = params.target as string;
      const count = (params.count as number) ?? 3;
      if (!target) throw new Error("target is required");
      return run(`tailscale ping --c ${count} ${target}`).trim();
    },
  });
}
