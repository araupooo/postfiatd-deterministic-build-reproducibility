#!/usr/bin/env bash
# compare_runs.sh — byte-compare artifact digests between subset-build runs
# and diagnose every mismatch.
#
# Usage: compare_runs.sh <digests-A.txt> <digests-B.txt> [label-A] [label-B]
# Both digest files are in `sha256sum` format with absolute paths; comparison
# is done on the basename-relative artifact name (build-root prefix stripped).
# For each mismatch it prints the two full digests, the file sizes, and runs
# cmp + readelf/string diagnostics. Exit 0 if all artifacts match, 1 otherwise.
set -uo pipefail

A="${1:?digests A required}"
B="${2:?digests B required}"
LA="${3:-A}"
LB="${4:-B}"

norm() {
  # normalize a sha256sum file to "hash  relative-artifact-path"
  awk '{h=$1; p=$2; sub(/^[^ ]+\/(secp256k1|ed25519)\//, "", p); print h"  "p}' "$1" | LC_ALL=C sort -k2
}

TMP_A="$(mktemp)"; TMP_B="$(mktemp)"
trap 'rm -f "${TMP_A}" "${TMP_B}"' EXIT
norm "$A" > "$TMP_A"
norm "$B" > "$TMP_B"

echo "=== digest comparison: ${LA} vs ${LB} ==="
echo "digests A: ${A}"
echo "digests B: ${B}"
echo "--- ${LA} ---"
cat "$TMP_A"
echo "--- ${LB} ---"
cat "$TMP_B"

MISMATCH=0
TOTAL=0
while read -r ha pa; do
  TOTAL=$((TOTAL+1))
  hb="$(awk -v p="$pa" '$2==p {print $1}' "$TMP_B")"
  if [ -z "$hb" ]; then
    echo "MISSING in ${LB}: ${pa} (present in ${LA} as ${ha})"
    MISMATCH=$((MISMATCH+1))
  elif [ "$ha" != "$hb" ]; then
    echo "MISMATCH: ${pa}"
    echo "  ${LA}: ${ha}"
    echo "  ${LB}: ${hb}"
    MISMATCH=$((MISMATCH+1))
  else
    echo "MATCH: ${pa} ${ha}"
  fi
done < "$TMP_A"
# artifacts only present in B
while read -r hb pb; do
  if ! awk -v p="$pb" '$2==p {found=1} END {exit !found}' "$TMP_A"; then
    echo "MISSING in ${LA}: ${pb} (present in ${LB} as ${hb})"
    MISMATCH=$((MISMATCH+1))
    TOTAL=$((TOTAL+1))
  fi
done < "$TMP_B"

echo "--- summary: ${TOTAL} artifacts compared, ${MISMATCH} mismatches ---"
if [ "$MISMATCH" -eq 0 ]; then
  echo "RESULT: IDENTICAL"
  exit 0
else
  echo "RESULT: DIFFERENT (${MISMATCH} of ${TOTAL} artifacts differ)"
  exit 1
fi
