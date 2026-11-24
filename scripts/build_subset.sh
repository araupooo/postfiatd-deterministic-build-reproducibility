#!/usr/bin/env bash
# build_subset.sh — build the self-contained vendored libraries from a
# pinned postfiatd source copy and record full SHA-256 digests.
#
# Usage:
#   build_subset.sh <run-label> <source-dir> <build-root> [compiler] [extra-cflags]
#
#   run-label   short label, e.g. R1 (used in log/digest filenames)
#   source-dir  absolute path to a postfiatd source copy at the pinned commit
#   build-root  absolute path to a fresh build directory (created by this script)
#   compiler    gcc (default) | gcc-12 | clang — must be on PATH
#   extra-cflags extra C flags, e.g. prefix-map remediation flags
#
# Builds, with project-equivalent Release flags (-O3 -DNDEBUG -g
# -fstack-protector, matching cmake/RippledCompiler.cmake which adds -g
# to Release builds):
#   * external/secp256k1  -> libsecp256k1.a (+ object files)
#   * external/ed25519-donna -> libed25519.a (+ object files)
#
# All output goes to stdout/stderr (caller redirects to an unedited log).
# Digests (FULL 64-hex SHA-256) are printed to stdout and written to
# <build-root>/digests.txt.
set -euo pipefail

LABEL="${1:?run label required}"
SRC="${2:?source dir required}"
BUILD_ROOT="${3:?build root required}"
CC_NAME="${4:-gcc}"
EXTRA_CFLAGS="${5:-}"

echo "=== subset build ${LABEL} ==="
echo "source dir : ${SRC}"
echo "build root : ${BUILD_ROOT}"
echo "compiler   : ${CC_NAME}"
echo "extra flags: ${EXTRA_CFLAGS:-<none>}"
echo "started    : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "pinned HEAD: $(git -C "${SRC}" rev-parse HEAD 2>/dev/null || echo UNKNOWN)"
echo "uname      : $(uname -a)"
echo "compiler version:"
"${CC_NAME}" --version | head -1
echo "cmake version: $(cmake --version | head -1)"
echo "ar version   : $(ar --version | head -1)"
echo "ld version   : $(ld --version | head -1)"

# Project-equivalent Release C flags. The top-level project adds -g to
# Release builds (cmake/RippledCompiler.cmake) and -fstack-protector.
CFLAGS="-O3 -DNDEBUG -g -fstack-protector -Wall ${EXTRA_CFLAGS}"
export CC="${CC_NAME}"
export CFLAGS

rm -rf "${BUILD_ROOT}"
mkdir -p "${BUILD_ROOT}"

# --- secp256k1 ---
echo "--- configuring secp256k1 ---"
cmake -S "${SRC}/external/secp256k1" -B "${BUILD_ROOT}/secp256k1" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="${CFLAGS}" \
  -DBUILD_SHARED_LIBS=OFF \
  -DSECP256K1_DISABLE_SHARED=ON \
  -DSECP256K1_BUILD_TESTS=OFF \
  -DSECP256K1_BUILD_EXHAUSTIVE_TESTS=OFF \
  -DSECP256K1_BUILD_BENCHMARK=OFF \
  -DSECP256K1_BUILD_CTIME_TESTS=OFF \
  -DSECP256K1_BUILD_EXAMPLES=OFF \
  -DSECP256K1_INSTALL=OFF
echo "--- building secp256k1 ---"
cmake --build "${BUILD_ROOT}/secp256k1" -j 2

# --- ed25519-donna ---
echo "--- configuring ed25519-donna ---"
cmake -S "${SRC}/external/ed25519-donna" -B "${BUILD_ROOT}/ed25519" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="${CFLAGS}"
echo "--- building ed25519-donna ---"
cmake --build "${BUILD_ROOT}/ed25519" -j 2

# --- digests: every produced object file and archive, FULL SHA-256 ---
echo "--- digests (SHA-256, full 64 hex chars) ---"
{
  echo "# ${LABEL} digests — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# source: ${SRC}"
  echo "# build : ${BUILD_ROOT}"
  find "${BUILD_ROOT}" \( -name '*.o' -o -name '*.a' -o -name '*.so' \) -type f | LC_ALL=C sort | while read -r f; do
    sha256sum "$f"
  done
} | tee "${BUILD_ROOT}/digests.txt"
echo "finished   : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "=== subset build ${LABEL} done ==="
