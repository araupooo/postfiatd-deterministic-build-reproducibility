# Claim-to-evidence index

Every measured claim in this pack maps to the script that produced it
and the unedited log that records it. Every specification claim maps
to its primary source. "UNMEASURED" means the claim is explicitly not
made — see `docs/findings-report.md`.

## Measured claims

| # | Claim | Script | Unedited evidence |
|---|---|---|---|
| C1 | Pinned commit is `0085a1ff885d6a446369cf73a4430f75af22be55` (2026-10-10, "Merge pull request #50 … hotfix/upstream-hardening-1.0.9"); HEAD unchanged from the two previous packs | `git ls-remote` + `git clone --depth 1` | `outputs/clone.log`; `outputs/blob-verification.txt` |
| C2 | All 15 key cited files agree blob-by-blob between the local checkout and the GitHub API tree at the pinned commit (SHA + size) | `git hash-object` vs API `git/trees/...?recursive=1` | `outputs/blob-verification.txt` (15/15 AGREE) |
| C3 | Same-path repeat is byte-identical: R1 == R2, 6/6 artifacts | `scripts/build_subset.sh`, `scripts/compare_runs.sh` | `outputs/subset-R1.log`, `outputs/subset-R2.log`, `outputs/compare-R1-R2.log` |
| C4 | Different absolute paths differ in all 6/6 artifacts (R1 vs R3) | `scripts/build_subset.sh`, `scripts/compare_runs.sh` | `outputs/subset-R3.log`, `outputs/compare-R1-R3.log` |
| C5 | The R1/R3 difference is exactly embedded absolute paths: identical sizes; 15 differing bytes in `secp256k1.c.o`, all `a`→`b` path characters; DWARF `DW_AT_comp_dir` = build dir, `DW_AT_name` = source path; `ar` members dated Jan 1 1970; no date strings | `cmp -l`, `readelf --debug-dump=info`, `strings`, `ar tv` | `outputs/diagnosis-R1-R3.log` |
| C6 | Prefix-map remediation restores byte-identical output: R1 == R4, 6/6 artifacts | `scripts/build_subset.sh` (R4 flags), `scripts/compare_runs.sh` | `outputs/subset-R4.log`, `outputs/compare-R1-R4.log` |
| C7 | gcc-12 (12.4.0) vs gcc-13 (13.3.0): 6/6 differ; `secp256k1.c.o` 1,051,568 vs 1,054,016 bytes, 621,329 differing bytes | `scripts/build_subset.sh`, `scripts/compare_runs.sh` | `outputs/subset-R5.log`, `outputs/compare-R1-R5.log` |
| C8 | clang 18.1.3 vs gcc 13.3.0: 6/6 differ; `secp256k1.c.o` 1,410,872 vs 1,054,016 bytes, 968,248 differing bytes; `DW_AT_producer` "Ubuntu clang version 18.1.3" | `scripts/build_subset.sh`, `scripts/compare_runs.sh` | `outputs/subset-R6.log`, `outputs/compare-R1-R6.log` |
| C9 | Re-running R3 from scratch reproduces R3's six digests exactly | `scripts/build_subset.sh` | `outputs/subset-R3diag.log` |
| C10 | No `__DATE__`/`__TIME__`/`__TIMESTAMP__` in `src/` or `include/`; no `SOURCE_DATE_EPOCH` handling; no prefix-map flags; `-g` added for Release (`cmake/RippledCompiler.cmake:107`); `--build-id` at `:111`; `GIT_COMMIT_HASH`/`GIT_BRANCH` defined at `CMakeLists.txt:37-47` | `scripts/audit_build_system.sh` | `outputs/static-audit.log` |
| C11 | `__FILE__` in 52 occurrences / 20 files, all in the test framework (`include/xrpl/beast/unit_test*.h`) and `src/test/*`; none in production code | `grep -rn __FILE__` on the local checkout | `outputs/file-macro-audit.log` |
| C12 | Every pinned dependency's source URL returns HTTP 200 (redirects followed); SHA-256 values as recorded in the resolved recipe revisions | `scripts/check_deps_fetchability.sh`, `scripts/conandata_lookup.py` | `outputs/deps-fetch-check.log`, `outputs/deps-cached-recipes.txt`, `outputs/deps-url-status.txt` |
| C13 | 7 pinned versions are no longer listed in conan-center-index master `conandata.yml` (grpc 1.50.1, soci 4.0.3, zlib 1.3.1, protobuf 3.21.12, date 3.0.4, sqlite3 3.49.1, rocksdb 10.0.1), but the Conan Center remote still serves their recipe revisions (grpc/1.50.1 revision `12e06d669d66951b6a381d695cb715d0` downloaded) | `scripts/check_deps_fetchability.sh`; `conan install` | `outputs/deps-fetch-check.log`; `outputs/conan-install-excerpt.log` |
| C14 | Full `postfiatd` binary build: attempted with the Dockerfile's exact commands; Conan resolved all recipes, downloaded 16 prebuilt binary packages, and built the rest from source; still building rocksdb (~59%) at pack time — **no full-binary digest exists** | `scripts/build_full.sh` (same commands as the live attempt) | `outputs/full-build-status.md` |
| C15 | Canonical R1 digests (6 artifacts, full SHA-256) | `scripts/build_subset.sh` | `outputs/subset-R1.log`, `run-manifest.json` |

## Specification / documentation claims (primary sources)

| # | Claim | Primary source |
|---|---|---|
| S1 | Compilers record the source path in debug info; `-fdebug-prefix-map`, `-fmacro-prefix-map`, `-ffile-prefix-map` are the workarounds | Reproducible Builds, "Build path", https://reproducible-builds.org/docs/build-path/ |
| S2 | `SOURCE_DATE_EPOCH` is the standardized build-date variable; CMake `STRING(TIMESTAMP ...)` respects it since 3.8 | Reproducible Builds, "SOURCE_DATE_EPOCH", https://reproducible-builds.org/docs/source-date-epoch/ |
| S3 | `-fdebug-prefix-map=old=new` records debug info "as if the files resided in directory *new*… This can give more reproducible builds, which are location independent" | GCC, "Debugging Options", https://gcc.gnu.org/onlinedocs/gcc/Debugging-Options.html |
| S4 | CMake `file(GLOB ...)` results "will be ordered lexicographically" since CMake 3.6 | CMake, `file` command, https://cmake.org/cmake/help/latest/command/file.html |
| S5 | Build requirements: Python 3.11+, Conan 2.17+, CMake 3.22+, GCC 12 / Clang 16; canonical Release build via `conan install` + CMake `-Dxrpld=ON` | Pinned `BUILD.md` (commit `0085a1ff`, verified blob `60e6c0001abe7566cc6458e70df5f00f61516699`) |
| S6 | Reference environment: Ubuntu 24.04, gcc-13, cmake 3.25.1 from the Kitware tarball, `conan install .. --build missing` (Release, compiler.version=13, cppstd=20, libstdc++11), `cmake -DCMAKE_BUILD_TYPE=Release -Dxrpld=ON -Dvalidator_keys=ON` | Pinned `Dockerfile` (commit `0085a1ff`, verified blob `71c0296dea3ab7bd640a2f54da735eccc266b4f4`) |
| S7 | `versionString = "1.0.9"` is pinned in source and read by CMake | Pinned `src/libxrpl/protocol/BuildInfo.cpp:39` (blob `8685f9ccf0ec0b6b79d69a641a66fb439c25a860`) and `cmake/RippledVersion.cmake` (blob `fda3cb6ff7bf4557dc2ec2d60471fc8664913613`) |

## UNMEASURED (explicitly not claimed)

| # | Dimension | Why |
|---|---|---|
| U1 | Full `postfiatd` binary byte-identical across two builds | Full build attempted, not completed on this VM (C14) |
| U2 | Two independent full environments (different distro/kernel) | Both subset builds ran on the same VM/kernel; only paths differed |
| U3 | Conan-built dependency reproducibility | Only recipe fetchability measured (C12–C13) |
| U4 | Test-binary (`-Dtests=ON`) reproducibility | Not built |
