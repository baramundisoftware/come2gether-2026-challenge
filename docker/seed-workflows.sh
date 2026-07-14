#!/bin/sh
#
# docker/seed-workflows.sh — REQ-IMG-005 / Phase 3 P3.5 + P3.6
#
# Idempotently imports the bundled workflow JSONs (under /seed/workflows/)
# into n8n's database with these transforms:
#   - Array-form exports (e.g. 31-lenovo-warranty-test.json) collapse to
#     a single-object workflow.
#   - Every node of type `n8n-nodes-baramundi.baramundi` rewires its
#     `credentials.bconnectApi` to id `bconnectdefault0` / name
#     "bConnect Mock (default)" — the credential P2.6 seeded.
#   - Tags normalised: any case-variant of `bconnect` is dropped, both
#     `bConnect` and `approved` are guaranteed present.
#   - External-API workflows (matched by name: CVE / Lenovo / Warranty)
#     are forced `active=false` and annotated with a sticky-note node
#     listing the env var that must be set before activation
#     (CLAUDE_API_KEY for CVE; LENOVO_API_KEY for Lenovo / Warranty).
#
# Idempotency:
#   - Skip workflows whose name already exists in n8n's DB
#     (`n8n list:workflow`).
#   - Marker file /home/node/.n8n/.workflows-seeded short-circuits the
#     entire run on subsequent boots; deleting it (or running this
#     script directly) re-attempts only the workflows still missing.
#
# Skip mechanism: setting `SEED_WORKFLOWS=false` makes the entrypoint
# bypass this script entirely (REQ-IMG-005 / P3.7).

set -eu

SRC_DIR="${SEED_WORKFLOWS_SRC:-/seed/workflows}"
STAGED_DIR="${SEED_WORKFLOWS_STAGED:-/tmp/staged-workflows}"
MARKER_DIR="${SEED_WORKFLOWS_MARKER_DIR:-/home/node/.n8n}"
MARKER="${MARKER_DIR}/.workflows-seeded"
CREDENTIAL_ID="bconnectdefault0"
CREDENTIAL_NAME="bConnect Mock (default)"

log()  { echo "[seed-workflows] $*"; }
warn() { echo "[seed-workflows] WARNING: $*" >&2; }

mkdir -p "${MARKER_DIR}"

# Collect existing workflow names (one per line) for dedupe-by-name.
# `n8n list:workflow` (n8n 1.x) prints `id|name|active` rows after a header.
existing_names() {
  n8n list:workflow 2>/dev/null \
    | awk -F'|' 'NR > 1 {
                   sub(/^ +/, "", $2); sub(/ +$/, "", $2);
                   if ($2 != "") print $2
                 }'
}
EXISTING_NAMES="$(existing_names || true)"

rm -rf "${STAGED_DIR}"
mkdir -p "${STAGED_DIR}"

prepared=0
skipped=0
total=0

# POSIX sh: glob with no matches expands to itself; guard with -f.
for src in "${SRC_DIR}"/*.json; do
  [ -f "${src}" ] || continue
  total=$((total + 1))
  base="$(basename "${src}" .json)"

  if jq -e 'type == "array"' < "${src}" >/dev/null 2>&1; then
    raw="$(jq -c '.[0] // empty' < "${src}")"
  else
    raw="$(jq -c '.' < "${src}")"
  fi
  if [ -z "${raw}" ]; then
    warn "skipping ${base}: cannot extract workflow object"
    continue
  fi

  name="$(printf '%s\n' "${raw}" | jq -r '.name // ""')"
  if [ -z "${name}" ]; then
    warn "skipping ${base}: empty .name"
    continue
  fi

  # Already imported? Skip.
  if printf '%s\n' "${EXISTING_NAMES}" | grep -Fxq "${name}"; then
    skipped=$((skipped + 1))
    continue
  fi

  # External-API classification by workflow name.
  env_var=""
  force_inactive=0
  case "${name}" in
    *CVE*|*cve*)
      env_var="CLAUDE_API_KEY"
      force_inactive=1
      ;;
    *Lenovo*|*lenovo*|*Warranty*|*warranty*)
      env_var="LENOVO_API_KEY"
      force_inactive=1
      ;;
  esac

  printf '%s\n' "${raw}" \
    | jq --arg cid   "${CREDENTIAL_ID}" \
         --arg cname "${CREDENTIAL_NAME}" \
         --argjson force_inactive "${force_inactive}" \
         --arg env_var "${env_var}" '
        # Drop fields that block re-import or duplicate metadata.
        del(.versionId, .triggerCount, .createdAt, .updatedAt, .pinData)

        # Rewire every bConnect node to the seeded credential. The
        # n8n custom-extension mechanism loads the suite under the
        # `CUSTOM.<nodeName>` namespace (vs the package name), so the
        # match is on the prefix, not the literal type string.
        | .nodes = ((.nodes // []) | map(
            if (.type | startswith("CUSTOM.baramundi")) then
              .credentials.bconnectApi = { id: $cid, name: $cname }
            else . end
          ))

        # Replace tags wholesale with the two spec-mandated tags. Stable
        # ids so the n8n CLI re-uses the same `tag_entity` row across all
        # 17 imports (avoids SQLITE_CONSTRAINT: UNIQUE tag_entity.name).
        # Pre-existing per-workflow tags (e.g. "support" on workflow 13)
        # are dropped — REQ-IMG-005 only mandates bConnect + approved.
        | .tags = [
            { id: "tagbconnect00000", name: "bConnect" },
            { id: "tagapproved00000", name: "approved" }
          ]

        # External-API workflows: force inactive + sticky-note with env var.
        | if $force_inactive == 1 then
            .active = false
            | .nodes = (.nodes + [{
                id: ("env-warn-" + (now | tostring)),
                name: "⚠️ Requires \($env_var)",
                type: "n8n-nodes-base.stickyNote",
                typeVersion: 1,
                position: [-200, -200],
                parameters: {
                  content: ("This workflow is **INACTIVE by default**.\n\n"
                          + "Set the `\($env_var)` environment variable on the\n"
                          + "container, then re-activate the workflow in the\n"
                          + "n8n UI.")
                }
              }])
          else . end
       ' > "${STAGED_DIR}/${base}.json"

  prepared=$((prepared + 1))
done

log "Source files: ${total}; staged: ${prepared}; already-present: ${skipped}"

if [ "${prepared}" -gt 0 ]; then
  n8n import:workflow --separate --input="${STAGED_DIR}"
fi

final_count="$(n8n list:workflow --onlyId 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
log "Total workflows in DB after seed: ${final_count}"

touch "${MARKER}"
log "Marker written: ${MARKER}"
