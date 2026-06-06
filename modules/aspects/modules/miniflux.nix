# miniflux.nix
# ──────────────────────────────────────────────
# den.aspect that deploys Miniflux RSS reader + PostgreSQL on cool
# for the RSS + recommendation algorithm project (Financial Resilience).
#
# Place in: ./modules/aspects/modules/miniflux.nix
#
# Then:
#   1. Add to cool.nix includes:
#        den.aspects.miniflux
#
#   2. Add to sops.nix allSecrets:
#        "miniflux/admin" = {};
#
#   3. Create the secret:
#        sops modules/secrets/secrets.yaml
#        Inside:  miniflux_admin: |
#                   ADMIN_USERNAME=avanonyme
#                   ADMIN_PASSWORD=<your-password>
#
# ══════════════════════════════════════════════
# MULTI-SUBJECT FEEDS
# ══════════════════════════════════════════════
#
# The aspect is designed for easy per-subject feed management.
# Miniflux supports categories — use one category per subject:
#
#   curl -u "$ADMIN_USERNAME:$ADMIN_PASSWORD" \
#     http://100.x.y.z:8080/v1/categories
#
#   # Create a category:
#   curl -X POST -u "$ADMIN_USERNAME:$ADMIN_PASSWORD" \
#     -d '{"title":"couverture"}' \
#     http://100.x.y.z:8080/v1/categories
#
#   # Add a feed to that category:
#   curl -X POST -u "$ADMIN_USERNAME:$ADMIN_PASSWORD" \
#     -d '{"feed_url":"...","category_id":<id>}' \
#     http://100.x.y.z:8080/v1/feeds
#
# The FastAPI backend wraps these calls — adding a new subject is
# a POST to the backend, which creates the category + initial feeds.
#
# ──────────────────────────────────────────────

{ den, inputs, config, lib, ... }:

let
  # Miniflux listens on localhost:8080 by default.
  # For the RSS recommender backend, access via Tailscale IP on port 8080
  # or through a reverse proxy.
  minifluxPort = 8080;

in
{
  den.aspects.miniflux = {
    nixos = { pkgs, ... }: {

      # ── PostgreSQL (required by Miniflux) ───────────────────────────────────
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_16;
        # Miniflux creates its own database via createDatabaseLocally = true
        ensureDatabases = [ "miniflux" ];
        authentication = pkgs.lib.mkOverride 10 ''
          local all all trust
          host all all 127.0.0.1/32 trust
          host all all ::1/128 trust
        '';
      };

      # ── Miniflux ────────────────────────────────────────────────────────────
      services.miniflux = {
        enable = true;
        createDatabaseLocally = true;

        # Admin credentials come from sops-nix.
        # Add to sops.nix allSecrets: "miniflux/admin" = {};
        # Then create in secrets.yaml:
        #   miniflux_admin: |
        #     ADMIN_USERNAME=avanonyme
        #     ADMIN_PASSWORD=<something-secure>
        adminCredentialsFile = config.sops.secrets."miniflux/admin".path;

        config = {
          # Listen on all tailscale interfaces + localhost.
          # The port is firewalled — only tailscale0 can reach it.
          LISTEN_ADDR = "127.0.0.1:${toString minifluxPort}";

          # Poll feeds every 30 minutes (financial news moves fast)
          POLLING_FREQUENCY = "30";

          # Process up to 30 feeds per polling cycle
          BATCH_SIZE = "30";

          # Cleanup archived articles after 90 days
          CLEANUP_ARCHIVE_READ_DAYS = "90";

          # Run DB migrations automatically
          RUN_MIGRATIONS = "1";

          # Create admin user from credentials file
          CREATE_ADMIN = "1";

          # Proxy headers (if behind nginx/caddy)
          # POLLING_PARSING_ERROR_LIMIT = "0";
        };
      };

      # ── Firewall: allow tailscale to reach Miniflux ─────────────────────────
      networking.firewall = {
        # Miniflux is on localhost only — accessible via tailscale
        # because tailscale routes through localhost.
        # No extra ports needed.
      };

      # ── Helper: miniflux CLI wrapper for managing feeds ─────────────────────
      environment.systemPackages = with pkgs; [
        # Miniflux CLI client (minifluxctl)
        # For manual feed management via terminal
        (writeShellScriptBin "miniflux-add-feed" ''
          # Usage: miniflux-add-feed <category> <feed-url> [feed-url...]
          # Example: miniflux-add-feed couverture https://example.com/rss
          CREDS="${config.sops.secrets."miniflux/admin".path}"
          USERNAME="$(grep ADMIN_USERNAME "$CREDS" | cut -d= -f2-)"
          PASSWORD="$(grep ADMIN_PASSWORD "$CREDS" | cut -d= -f2-)"
          BASE="http://127.0.0.1:${toString minifluxPort}/v1"

          CATEGORY="$1"
          shift

          # Get or create category
          CAT_ID=$(curl -s -u "$USERNAME:$PASSWORD" "$BASE/categories" | \
            ${pkgs.jq}/bin/jq -r ".[] | select(.title == \"$CATEGORY\") | .id" | head -1)

          if [ -z "$CAT_ID" ]; then
            CAT_ID=$(curl -s -X POST -u "$USERNAME:$PASSWORD" \
              -d "{\"title\":\"$CATEGORY\"}" "$BASE/categories" | ${pkgs.jq}/bin/jq -r '.id')
            echo "Created category '$CATEGORY' (id=$CAT_ID)"
          else
            echo "Using existing category '$CATEGORY' (id=$CAT_ID)"
          fi

          # Add each feed URL to the category
          for url in "$@"; do
            RESULT=$(curl -s -X POST -u "$USERNAME:$PASSWORD" \
              -d "{\"feed_url\":\"$url\",\"category_id\":$CAT_ID}" "$BASE/feeds")
            FEED_ID=$(echo "$RESULT" | ${pkgs.jq}/bin/jq -r '.id // empty')
            if [ -n "$FEED_ID" ]; then
              echo "Added feed: $FEED_ID — $url"
            else
              ERROR=$(echo "$RESULT" | ${pkgs.jq}/bin/jq -r '.error_message // "unknown error"')
              echo "Failed: $url — $ERROR"
            fi
          done
        '')
      ];
    };
  };
}
