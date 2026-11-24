#!/usr/bin/env bash
# verify_digests.sh — verify every file listed in SHA256SUMS.
# Usage: run from the pack root: scripts/verify_digests.sh
set -euo pipefail
cd "$(dirname "$0")/.."
sha256sum -c SHA256SUMS
