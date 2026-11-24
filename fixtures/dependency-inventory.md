# Dependency and toolchain inventory

Pinned commit: `0085a1ff885d6a446369cf73a4430f75af22be55`.
All source URLs and SHA-256 values below were taken from the exact
recipe revisions Conan resolved from Conan Center during the live
`conan install` in this audit (see `outputs/deps-cached-recipes.txt`),
and every URL was fetch-checked live (HTTP 200, redirects followed;
see `outputs/deps-url-status.txt`). Where a pinned version is no longer
in conan-center-index master, that is noted — the recipe revision is
still served by the Conan Center remote.

## Direct dependencies (pinned in `conanfile.py`)

| Dependency | Pinned version | Source URL | Recorded SHA-256 | Fetch |
|---|---|---|---|---|
| grpc | 1.50.1 | https://github.com/grpc/grpc/archive/v1.50.1.tar.gz | `fb1ed98eb3555877d55eb2b948caca44bc8601c6704896594de81558639709ef` | 200 |
| libarchive | 3.8.1 | https://github.com/libarchive/libarchive/releases/download/v3.8.1/libarchive-3.8.1.tar.xz | `19f917d42d530f98815ac824d90c7eaf648e9d9a50e4f309c812457ffa5496b5` | 200 |
| nudb | 2.0.9 | https://github.com/CPPAlliance/NuDB/archive/2.0.9.tar.gz | `a088dac72931f7b51b4def1f1b505e4e6c4d1c8c8b41fa3c5f70b989ddcaeba9` | 200 |
| openssl | 1.1.1w | https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-1.1.1w.tar.gz | `cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8` | 200 |
| soci | 4.0.3 | https://github.com/SOCI/soci/archive/v4.0.3.tar.gz | `4b1ff9c8545c5d802fbe06ee6cd2886630e5c03bf740e269bb625b45cf934928` | 200 |
| zlib | 1.3.1 | https://zlib.net/fossils/zlib-1.3.1.tar.gz (mirror: https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz) | `9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23` | 200 |
| doctest (test) | 2.4.11 | https://github.com/doctest/doctest/archive/refs/tags/v2.4.11.tar.gz | `632ed2c05a7f53fa961381497bf8069093f0d6628c5f26286161fbd32a560186` | 200 |
| protobuf (tool) | 3.21.12 | https://github.com/protocolbuffers/protobuf/archive/refs/tags/v3.21.12.tar.gz | `930c2c3b5ecc6c9c12615cf5ad93f1cd6e12d0aba862b572e076259970ac3a53` | 200 |
| boost | 1.83.0 | https://archives.boost.io/release/1.83.0/source/boost_1_83_0.tar.bz2 (mirror: SourceForge) | `6478edfe2f3305127cffe8caf73ea0176c53769f4bf1585be237eb30798c3b8e` | 200 |
| date | 3.0.4 | https://github.com/HowardHinnant/date/archive/refs/tags/v3.0.4.tar.gz | `56e05531ee8994124eeb498d0e6a5e1c3b9d4fccbecdf555fe266631368fb55f` | 200 |
| lz4 | 1.10.0 | https://github.com/lz4/lz4/archive/v1.10.0.tar.gz | `537512904744b35e232912055ccf8ec66d768639ff3abe5788d90d792ec5f48b` | 200 |
| sqlite3 | 3.49.1 | https://sqlite.org/2025/sqlite-amalgamation-3490100.zip | `6cebd1d8403fc58c30e93939b246f3e6e58d0765a5cd50546f16c00fd805d2c3` | 200 |
| rocksdb | 10.0.1 | https://github.com/facebook/rocksdb/archive/refs/tags/v10.0.1.tar.gz | `3fdc9ca996971c4c039959866382c4a3a6c8ade4abf888f3b2ff77153e07bf28` | 200 |
| xxhash | 0.8.3 | https://github.com/Cyan4973/xxHash/archive/v0.8.3.tar.gz | `aae608dfe8213dfd05d909a57718ef82f30722c392344583d3f39050c7f29a80` | 200 |
| snappy (patched recipe, BUILD.md) | 1.1.10 | https://github.com/google/snappy/archive/1.1.10.tar.gz | `49d831bffcc5f3d01482340fe5af59852ca2fe76c3e05df0e67203ebbe0f1d90` | 200 |
| jemalloc (optional) | 5.3.0 | https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2 | `2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa` | 200 |

## Resolved transitive dependencies (from the live `conan install`)

| Dependency | Resolved version | Source URL | Recorded SHA-256 | Fetch |
|---|---|---|---|---|
| abseil (grpc) | 20230802.1 | https://github.com/abseil/abseil-cpp/archive/20230802.1.tar.gz | `987ce98f02eefbaf930d6e38ab16aa05737234d7afbab2d5c4ea7adbe50c28ed` | 200 |
| c-ares (grpc) | 1.34.9 | https://github.com/c-ares/c-ares/releases/download/v1.34.9/c-ares-1.34.9.tar.gz | `9364b70a12eb59a06830fb488d9357f90100dff0d98b23ea3593a183d43e6f2f` | 200 |
| re2 (grpc) | 20230301 | https://github.com/google/re2/archive/refs/tags/2023-03-01.tar.gz | `7a9a4824958586980926a300b4717202485c4b4115ac031822e29aa4ef207e48` | 200 |
| bzip2 | 1.0.8 | https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz | `ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269` | 200 |
| snappy (via rocksdb) | 1.2.1 | https://github.com/google/snappy/archive/1.2.1.tar.gz | `736aeb64d86566d2236ddffa2865ee5d7a82d26c9016b36218fcc27ea4f09f86` | 200 |

## Vendored in-tree libraries (no external fetch)

| Library | Files at pinned commit |
|---|---|
| `external/secp256k1` | 165 |
| `external/ed25519-donna` | 42 |
| `external/antithesis-sdk` | 5 |

## Toolchain inventory (audit machine)

| Tool | Version | Source |
|---|---|---|
| OS | Ubuntu 24.04.5 LTS, kernel 7.0.0-44-generic, x86_64 | `lsb_release`, `uname -a` |
| gcc / g++ | 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04.1) | `gcc --version` |
| gcc-12 / g++-12 | 12.4.0 (installed for R5) | `apt install gcc-12 g++-12` |
| clang | 18.1.3 (installed for R6) | `apt install clang` |
| cmake | 3.28.3 | `cmake --version` |
| GNU ld / ar / ranlib | 2.42 | `ld --version` |
| Python | 3.12.3 | `python3 --version` |
| Conan | 2.34.0 | `conan --version` (venv) |
| System OpenSSL | 3.0.13 (`libssl-dev`) | `dpkg -l libssl-dev` |
| Boost runtime libs | 1.83.0 (no dev headers installed) | `dpkg -l libboost-*` |

Reference toolchain (pinned `Dockerfile`): Ubuntu 24.04, gcc-13/g++-13,
cmake 3.25.1 (built from
https://github.com/Kitware/CMake/releases/download/v3.25.1/cmake-3.25.1.tar.gz
— fetch 200), Conan via pipx, `libssl-dev`, `libprotobuf-dev`,
`protobuf-compiler`.

## Notes

- **Versions no longer in conan-center-index master:** grpc 1.50.1,
  soci 4.0.3, zlib 1.3.1, protobuf 3.21.12, date 3.0.4, sqlite3 3.49.1,
  rocksdb 10.0.1. The Conan Center remote still serves their recipe
  revisions (grpc/1.50.1 revision
  `12e06d669d66951b6a381d695cb715d0` was downloaded live), and every
  upstream source tarball is still fetchable. Risk: drift, not
  breakage — a future re-resolve against master may pick different
  recipe revisions.
- **Snappy discrepancy:** `BUILD.md` documents a patched snappy 1.1.10
  recipe from the XRPLF conan-center-index fork, to be used via the
  `xrplf` remote (`https://conan.ripplex.io`). The `Dockerfile` flow
  does not add that remote, so the live `conan install` resolved
  snappy 1.2.1 as a transitive dependency of rocksdb instead. The two
  documented build paths therefore do not build the same snappy.
  This is a build-drift finding, not a reproducibility measurement.
- **OpenSSL 1.1.1w** is end-of-life upstream (1.1.1 EOL was
  2023-09-11); the pinned recipe still fetches fine. Not a
  reproducibility issue, noted for the remediation backlog.
