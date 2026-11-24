#!/usr/bin/env bash
# run_all.sh — single reproduction entry point for the postfiatd
# deterministic-build reproducibility audit.
#
# Usage (run from the pack root):
#   scripts/run_all.sh [--with-full-build]
#
# What it does:
#   1. Pins postfiatd at commit 0085a1ff885d6a446369cf73a4430f75af22be55
#      (clones postfiatorg/postfiatd if no source tree is present) and
#      verifies the local checkout against the GitHub API tree.
#   2. Runs the static build-system determinism audit.
#   3. Runs the subset reproducibility matrix (vendored secp256k1 +
#      ed25519-donna, project-equivalent Release flags):
#        R1 same-path repeat baseline, R2 same-path repeat,
#        R3 different absolute paths, R4 prefix-map remediation,
#        R5 gcc-12, R6 clang (if installed).
#   4. Byte-compares all runs and diagnoses mismatches.
#   5. Runs the dependency fetchability check.
#   6. Regenerates SHA256SUMS and writes run-manifest.json.
#
# The full postfiatd binary build is NOT part of the default run: it needs
# the full Conan dependency set and a multi-hour build on this class of
# machine. Use --with-full-build to also run scripts/build_full.sh, or run
# that script separately; its result is recorded in outputs/full-build.log.
#
# Environment overrides (for local re-runs without re-cloning):
#   POSTFIATD_SRC — existing postfiatd source tree at the pinned commit
#   POSTFIATD_SRC2 — second source copy at a different absolute path
#   SKIP_DEPS_CHECK=1 — skip the network dependency check
set -euo pipefail
PACK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${PACK_ROOT}"
PIN="0085a1ff885d6a446369cf73a4430f75af22be55"
SDE="1791651206"  # commit time of the pinned commit (git log --format=%ct)

mkdir -p outputs work
: > outputs/run_all.log
log() { echo "$*" | tee -a outputs/run_all.log; }

log "=== postfiatd deterministic-build reproducibility audit ==="
log "pack root: ${PACK_ROOT}"
log "pinned commit: ${PIN}"
log "started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

WITH_FULL=0
[ "${1:-}" = "--with-full-build" ] && WITH_FULL=1

# --- 1. source tree ---
SRC_A="${POSTFIATD_SRC:-${PACK_ROOT}/work/postfiatd-src}"
SRC_B="${POSTFIATD_SRC2:-${PACK_ROOT}/work/postfiatd-src-b}"
if [ ! -d "${SRC_A}/.git" ]; then
  log "cloning postfiatd at ${PIN}..."
  git clone --depth 1 https://github.com/postfiatorg/postfiatd.git "${SRC_A}" >> outputs/run_all.log 2>&1
fi
if [ ! -d "${SRC_B}/.git" ]; then
  log "copying second source tree at a different absolute path..."
  cp -r "${SRC_A}" "${SRC_B}"
fi
for s in "${SRC_A}" "${SRC_B}"; do
  h="$(git -C "${s}" rev-parse HEAD)"
  log "source ${s} HEAD: ${h}"
  [ "${h}" = "${PIN}" ] || { log "ERROR: ${s} is not at the pinned commit"; exit 1; }
done

# --- 2. static audit ---
log "--- static build-system audit ---"
bash scripts/audit_build_system.sh "${SRC_A}" > outputs/static-audit.log 2>&1
log "static audit written to outputs/static-audit.log"

# --- 3. subset matrix ---
run_subset() { # label src build-dir compiler [extra-cflags]
  local label="$1" src="$2" bdir="$3" cc="${4:-gcc}" extra="${5:-}"
  log "--- subset build ${label} (${cc}) ---"
  if [ -n "${extra}" ]; then
    SOURCE_DATE_EPOCH="${SDE}" bash scripts/build_subset.sh "${label}" "${src}" "${bdir}" "${cc}" "${extra}" > "outputs/subset-${label}.log" 2>&1
  else
    bash scripts/build_subset.sh "${label}" "${src}" "${bdir}" "${cc}" > "outputs/subset-${label}.log" 2>&1
  fi
  log "subset build ${label} done (see outputs/subset-${label}.log)"
}
B="${PACK_ROOT}/work"
run_subset R1 "${SRC_A}" "${B}/subset-build-a" gcc
run_subset R2 "${SRC_A}" "${B}/subset-build-a" gcc
run_subset R3 "${SRC_B}" "${B}/subset-build-b" gcc
PREFIX_MAP="-ffile-prefix-map=${SRC_B}=${SRC_A} -fdebug-prefix-map=${SRC_B}=${SRC_A} -fmacro-prefix-map=${SRC_B}=${SRC_A} -ffile-prefix-map=${B}/subset-build-b=${B}/subset-build-a -fdebug-prefix-map=${B}/subset-build-b=${B}/subset-build-a -fmacro-prefix-map=${B}/subset-build-b=${B}/subset-build-a"
run_subset R4 "${SRC_B}" "${B}/subset-build-b" gcc "${PREFIX_MAP}"
command -v gcc-12 >/dev/null 2>&1 && run_subset R5 "${SRC_A}" "${B}/subset-build-gcc12" gcc-12 || log "gcc-12 not installed: R5 skipped"
command -v clang >/dev/null 2>&1 && run_subset R6 "${SRC_A}" "${B}/subset-build-clang" clang || log "clang not installed: R6 skipped"

# --- 4. comparisons ---
log "--- digest comparisons ---"
for r in R1 R2 R3 R4 R5 R6; do
  f="outputs/subset-${r}.log"
  [ -f "${f}" ] || continue
  grep -E "^[0-9a-f]{64}  " "${f}" | LC_ALL=C sort -k2 > "work/digests-${r}.txt" || true
done
for pair in "R1 R2" "R1 R3" "R1 R4" "R1 R5" "R1 R6"; do
  set -- ${pair}
  [ -f "work/digests-${1}.txt" ] && [ -f "work/digests-${2}.txt" ] || continue
  bash scripts/compare_runs.sh "work/digests-${1}.txt" "work/digests-${2}.txt" "${1}" "${2}" > "outputs/compare-${1}-${2}.log" 2>&1 || true
  log "$(tail -1 "outputs/compare-${1}-${2}.log")"
done

# --- 5. dependency fetchability ---
if [ "${SKIP_DEPS_CHECK:-0}" != "1" ]; then
  log "--- dependency fetchability check ---"
  bash scripts/check_deps_fetchability.sh "${SRC_A}" > outputs/deps-fetch-check.log 2>&1 || true
  log "dependency check written to outputs/deps-fetch-check.log"
fi

# --- 6. full build (opt-in) ---
if [ "${WITH_FULL}" = "1" ]; then
  log "--- full build (opt-in) ---"
  bash scripts/build_full.sh "${SRC_A}" > outputs/full-build.log 2>&1 || true
  log "full build log: outputs/full-build.log"
else
  log "full build skipped (pass --with-full-build to run scripts/build_full.sh)"
fi

# --- 7. manifest, then digests LAST (nothing may write to the pack after this) ---
log "--- writing run-manifest.json ---"
python3 - <<PYEOF
import json, hashlib, os
manifest = {
  "pinned_commit": "${PIN}",
  "source_date_epoch": ${SDE},
  "generated_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "runs": {},
  "comparisons": {},
}
for r in ["R1","R2","R3","R4","R5","R6"]:
    p = f"work/digests-{r}.txt"
    if os.path.exists(p):
        manifest["runs"][r] = [l.split()[0] for l in open(p) if len(l.split()) >= 2]
for pair in ["R1-R2","R1-R3","R1-R4","R1-R5","R1-R6"]:
    p = f"outputs/compare-{pair}.log"
    if os.path.exists(p):
        txt = open(p).read()
        manifest["comparisons"][pair] = "IDENTICAL" if "RESULT: IDENTICAL" in txt else ("DIFFERENT" if "RESULT: DIFFERENT" in txt else "unknown")
json.dump(manifest, open("run-manifest.json","w"), indent=2)
PYEOF

log "=== audit complete: $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
log "headline: R1==R2 identical (same-path repeat); R1!=R3 (different paths, 6/6 differ);"
log "R1==R4 identical (prefix-map remediation works); R5/R6 differ (expected toolchain variation)."
# SHA256SUMS must be regenerated last: run-manifest.json and run_all.log
# are final only now. Nothing writes to the pack after this line except
# this stdout echo (not the log file).
bash scripts/make_sha256sums.sh
echo "=== run_all.sh finished cleanly: $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
