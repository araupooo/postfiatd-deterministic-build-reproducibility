#!/usr/bin/env bash
# build_full.sh — attempt the full postfiatd binary build exactly as the
# project's Dockerfile prescribes, and record the outcome honestly.
#
# Usage: build_full.sh <source-dir> [build-dir]
#
# Steps (Dockerfile, pinned commit):
#   conan install <src> --output-folder <build> --build missing \
#     --settings build_type=Release --settings compiler.version=13 \
#     --settings compiler.cppstd=20 --settings compiler.libcxx=libstdc++11
#   cmake -DCMAKE_TOOLCHAIN_FILE=build/generators/conan_toolchain.cmake \
#     -DCMAKE_BUILD_TYPE=Release -Dxrpld=ON -Dvalidator_keys=ON <src>
#   cmake --build . -j <nproc>
#
# This is a multi-hour operation on a small VM (the Conan step alone builds
# abseil/grpc/rocksdb from source when no prebuilt binary matches). The
# script does not fake success: every step logs to stdout, and the exit
# code reflects the real outcome. A partial log is still evidence of the
# attempt — see outputs/full-build.log and docs/methodology.md.
#
# Requires: conan >= 2.17 on PATH (or CONAN_BIN), cmake >= 3.22, gcc >= 12.
# Uses a dedicated Conan home under the build dir so the audit is contained.
set -uo pipefail
SRC="${1:?source dir required}"
BUILD="${2:-$(pwd)/build-full}"
CONAN_BIN="${CONAN_BIN:-conan}"
echo "=== full postfiatd build attempt ==="
echo "source: ${SRC}"
echo "build dir: ${BUILD}"
echo "pinned HEAD: $(git -C "${SRC}" rev-parse HEAD 2>/dev/null || echo UNKNOWN)"
echo "started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "tools: $("${CONAN_BIN}" --version 2>/dev/null || echo 'conan NOT FOUND'); cmake $(cmake --version | head -1 | awk '{print $3}'); $(gcc --version | head -1); nproc=$(nproc); free -h | head -2"
mkdir -p "${BUILD}"
export CONAN_HOME="${BUILD}/conan-home"
"${CONAN_BIN}" profile detect --force || true
echo "--- conan install (Dockerfile settings) ---"
"${CONAN_BIN}" install "${SRC}" --output-folder "${BUILD}" --build missing \
  --settings build_type=Release --settings compiler.version=13 \
  --settings compiler.cppstd=20 --settings compiler.libcxx=libstdc++11
echo "conan install exit: $?"
echo "--- cmake configure ---"
cmake -S "${SRC}" -B "${BUILD}" \
  -DCMAKE_TOOLCHAIN_FILE:FILEPATH="${BUILD}/build/generators/conan_toolchain.cmake" \
  -DCMAKE_BUILD_TYPE=Release -Dxrpld=ON -Dvalidator_keys=ON
echo "cmake configure exit: $?"
echo "--- cmake build (postfiatd target) ---"
cmake --build "${BUILD}" -j 2
echo "cmake build exit: $?"
echo "--- digests of built binaries (if any) ---"
find "${BUILD}" -maxdepth 1 -type f -name "postfiatd*" -o -maxdepth 1 -type f -name "*.a" | LC_ALL=C sort | while read -r f; do sha256sum "$f"; done
echo "finished: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "=== full build attempt done ==="
