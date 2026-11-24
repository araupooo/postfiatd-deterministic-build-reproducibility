#!/usr/bin/env bash
# check_deps_fetchability.sh — primary-source fetchability check for every
# pinned dependency of postfiatd at the pinned commit.
#
# For each dependency pinned in conanfile.py (plus the Dockerfile's system
# packages and the vendored in-tree libraries), this script:
#   1. prints the pinned version and where it is pinned (file:line),
#   2. fetches the upstream recipe's conandata.yml from conan-center-index
#      and extracts the recorded source URL + SHA-256 for the pinned version,
#   3. issues an HTTP request following redirects against the source URL and
#      records the final status — proving the pinned source is still fetchable.
#
# Usage: check_deps_fetchability.sh <source-dir>
# Output goes to stdout (caller redirects to an unedited log). Exit 0 even
# if some checks fail — failures are recorded in the output, not hidden.
set -uo pipefail
SRC="${1:?source dir required}"
HERE="$(cd "$(dirname "$0")" && pwd)"
echo "=== dependency fetchability check ==="
echo "source: ${SRC}"
echo "pinned HEAD: $(git -C "${SRC}" rev-parse HEAD 2>/dev/null || echo UNKNOWN)"
echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "conanfile pins (grep, conanfile.py):"
grep -n "requires\|requires =" "${SRC}/conanfile.py" | head -30

check_recipe() {
  local name="$1" version="$2" cdata_url="$3"
  echo
  echo "--- ${name} ${version} ---"
  echo "recipe conandata: ${cdata_url}"
  local info url code
  info="$(python3 "${HERE}/conandata_lookup.py" "${name}" "${version}" "${cdata_url}")"
  echo "${info}"
  url="$(echo "${info}" | sed -n 's/^source url: //p')"
  if [ -n "${url}" ] && [ "${url}" != "None" ]; then
    code="$(curl -s -L -o /dev/null -w '%{http_code}' --max-time 90 "${url}" || echo 000)"
    echo "source fetch status (following redirects): ${code}"
  else
    echo "source fetch status: NOT CHECKED (no URL extracted)"
  fi
}

CCI="https://raw.githubusercontent.com/conan-io/conan-center-index/master/recipes"
check_recipe "grpc"       "1.50.1"  "${CCI}/grpc/all/conandata.yml"
check_recipe "libarchive" "3.8.1"   "${CCI}/libarchive/all/conandata.yml"
check_recipe "nudb"       "2.0.9"   "${CCI}/nudb/all/conandata.yml"
check_recipe "openssl"    "1.1.1w"  "${CCI}/openssl/1.x.x/conandata.yml"
check_recipe "soci"       "4.0.3"   "${CCI}/soci/all/conandata.yml"
check_recipe "zlib"       "1.3.1"   "${CCI}/zlib/all/conandata.yml"
check_recipe "doctest"    "2.4.11"  "${CCI}/doctest/all/conandata.yml"
check_recipe "protobuf"   "3.21.12" "${CCI}/protobuf/all/conandata.yml"
check_recipe "boost"      "1.83.0"  "${CCI}/boost/all/conandata.yml"
check_recipe "date"       "3.0.4"   "${CCI}/date/all/conandata.yml"
check_recipe "lz4"        "1.10.0"  "${CCI}/lz4/all/conandata.yml"
check_recipe "sqlite3"    "3.49.1"  "${CCI}/sqlite3/all/conandata.yml"
check_recipe "rocksdb"    "10.0.1"  "${CCI}/rocksdb/all/conandata.yml"
check_recipe "xxhash"     "0.8.3"   "${CCI}/xxhash/all/conandata.yml"
check_recipe "snappy"     "1.1.10"  "${CCI}/snappy/all/conandata.yml"
check_recipe "jemalloc"   "5.3.0"   "${CCI}/jemalloc/all/conandata.yml"

echo
echo "--- doctest recipe layout (conandata.yml 404s; inspect conanfile.py directly) ---"
curl -fsSL --max-time 60 "${CCI}/doctest/all/conanfile.py" 2>/dev/null | grep -in "url\|archive\|github" | head -8 || echo "doctest conanfile.py fetch FAILED"

echo
echo "--- vendored in-tree libraries (no external fetch; present at pinned commit) ---"
for d in secp256k1 ed25519-donna antithesis-sdk; do
  if [ -d "${SRC}/external/${d}" ]; then
    echo "vendored: external/${d} — present, $(find "${SRC}/external/${d}" -type f | wc -l) files"
  else
    echo "vendored: external/${d} — MISSING"
  fi
done

echo
echo "--- Dockerfile system packages (Ubuntu 24.04 apt) ---"
grep -n "apt install" "${SRC}/Dockerfile"
echo "cmake 3.25.1 tarball (Dockerfile builds cmake from source):"
curl -s -L -o /dev/null -w 'fetch status (following redirects): %{http_code}\n' --max-time 90 "https://github.com/Kitware/CMake/releases/download/v3.25.1/cmake-3.25.1.tar.gz" || echo "cmake tarball fetch: FAILED"

echo
echo "=== dependency fetchability check done ==="
