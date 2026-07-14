#!/bin/sh
#
# n8n-demo container entrypoint — REQ-IMG-001 / REQ-IMG-006 / REQ-IMG-004
#
# Started under `tini -g --` per the Dockerfile ENTRYPOINT. tini reaps
# zombies and forwards signals to every process in our process group,
# which is how the backgrounded bConnect Mock receives SIGTERM after we
# `exec` n8n.
#
# Sequence (Phase 2 P2.5):
#   1. Translate REQ-IMG-004 user-facing env vars to the actual env vars
#      the upstream `bconnect-mock` binary honors (PORT, BIND_ADDRESS,
#      BCONNECT_PROFILE, FIXTURES_ROOT).
#   2. Pick fixture source: user-mounted /seed/mock-profile/<profile>/ if
#      non-empty, else mock's bundled fixtures (REQ-IMG-006 selection rule).
#   3. Start the mock in the background, install a TERM/INT/HUP trap.
#   4. Poll mock /health for up to 30 s; abort on timeout or premature exit.
#   5. exec n8n as the foreground process. tini -g propagates SIGTERM to
#      both n8n (foreground) and the orphaned mock (group member).
#
# P2.6 will append first-boot credential seeding after n8n is healthy.

set -eu

# --- demo banner (REQ-IMG-008 rule #4) -------------------------------------
# Printed first so `docker logs` captures it before any of the slower
# startup work (mock launch, n8n migrations, workflow seed). Tests poll
# for "MOCK" + "Do not point production" within 5 s of container start.
cat <<'BANNER'
=============================================================================
 come2gether 2026 Challenge — n8n demo image (n8n + baramundi Connector).
 Targets an external bConnect (mock service or real bMS) via BCONNECT_BASE_URL.
 Demo / dev only — do not point production workflows at this container.
=============================================================================
BANNER

# NOTE on REQ-IMG-008 rule #3 ("DEMO PASSWORD" banner in editor UI):
# Originally Phase 5 P5.5 injected an in-app banner referencing
# N8N_BASIC_AUTH_PASSWORD. n8n 1.65 deprecated basic auth, so the
# referenced env var doesn't actually authenticate anything — the user
# creates their own owner credentials at /setup. The injected banner
# was misleading AND covered part of the n8n top nav. Dropped here;
# the stdout banner above (REQ-IMG-008 rule #4 — "MOCK / Do not point
# production") and SECURITY.md still cover the not-for-production
# message. If a future spec revision settles on owner-setup-aware
# wording, re-add the injection here.

# --- bConnect target -------------------------------------------------------
# This image does NOT bundle a mock. n8n always targets an external bConnect
# (the bconnect-mock service from docker-compose, or a real bMS) configured
# via BCONNECT_BASE_URL + BCONNECT_USERNAME + BCONNECT_PASSWORD. The seeded
# credential below picks up BCONNECT_BASE_URL from env.
echo "[entrypoint] n8n will target BCONNECT_BASE_URL=${BCONNECT_BASE_URL:-<unset>}"

# --- first-boot: seed the default bConnect credential (REQ-IMG-004 / P2.6) -
# Idempotent: a marker file under /home/node/.n8n/ short-circuits on restart.
# Runs synchronously before n8n starts so we don't race n8n on DB migrations.
seed_default_credential() {
  marker="/home/node/.n8n/.credential-seeded"
  if [ -f "${marker}" ]; then
    echo "[entrypoint] Default credential already seeded; skipping"
    return 0
  fi

  echo "[entrypoint] Seeding default bConnect credential ('bConnect Mock (default)')"

  # n8n lazily creates ~/.n8n on first run; create it now so the marker has
  # a home and `n8n import:credentials` finds the writable config dir.
  mkdir -p /home/node/.n8n

  # Build the credential JSON safely (jq handles all string escaping).
  # Fixed path with strict umask: busybox `mktemp` doesn't accept a `.json`
  # suffix after the template, and the file is short-lived so a race-prone
  # PRNG name buys nothing here.
  umask 077
  tmp="/tmp/cred.$$.json"
  rm -f "${tmp}"

  # Stable 16-char credential id so Phase 3's seed-workflows.sh can rewire
  # every bConnect node to it without maintaining a runtime lookup.
  if jq -n \
       --arg url  "${BCONNECT_BASE_URL:-http://127.0.0.1:8080}" \
       --arg user "${BCONNECT_USERNAME:-mockuser}" \
       --arg pass "${BCONNECT_PASSWORD:-mockpass}" \
       '[{
          id: "bconnectdefault0",
          name: "bConnect Mock (default)",
          type: "bconnectApi",
          data: { baseUrl: $url, username: $user, password: $pass, ignoreSslIssues: false }
        }]' > "${tmp}" \
     && n8n import:credentials --input="${tmp}"; then
    touch "${marker}"
    echo "[entrypoint] Default credential seeded"
  else
    echo "[entrypoint] WARNING: credential seed failed; container will start without it" >&2
  fi

  rm -f "${tmp}"
}

seed_default_credential

# --- first-boot: seed the bundled example workflows (REQ-IMG-005 / P3.5) ---
# Skippable via SEED_WORKFLOWS=false. The seed script itself is idempotent
# (marker file + dedupe-by-name), so re-running on restart is a no-op.
if [ "${SEED_WORKFLOWS:-true}" = "true" ]; then
  if ! /seed-workflows.sh; then
    echo "[entrypoint] WARNING: workflow seed failed; container will start anyway" >&2
  fi
else
  echo "[entrypoint] SEED_WORKFLOWS=false; skipping workflow import"
fi

# --- exec n8n -------------------------------------------------------------
# `exec` replaces this script with the n8n process; tini -g still receives
# signals as PID 1 and forwards them to the whole group (mock + n8n).
echo "[entrypoint] Starting n8n"
exec n8n "$@"
