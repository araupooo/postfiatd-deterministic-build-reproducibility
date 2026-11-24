#!/usr/bin/env bash
# make_sha256sums.sh — regenerate SHA256SUMS for every file in the pack
# except SHA256SUMS itself. Run from the pack root.
# outputs/run_all.log is excluded: it is a transient log created by each
# run_all.sh run and is never shipped, so digesting it would make a fresh
# copy's digest count differ from the pack's.
set -euo pipefail
cd "$(dirname "$0")/.."
find . -type f ! -name SHA256SUMS ! -path "./work/*" ! -path "./outputs/run_all.log" ! -name ".git*" | LC_ALL=C sort | xargs sha256sum > SHA256SUMS
echo "SHA256SUMS regenerated: $(wc -l < SHA256SUMS) entries"
