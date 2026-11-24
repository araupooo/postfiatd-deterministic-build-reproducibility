# Findings and remediation report

Pinned commit: `0085a1ff885d6a446369cf73a4430f75af22be55`
(2026-10-10, "Merge pull request #50 … hotfix/upstream-hardening-1.0.9").
Audit date: 2026-11-24. Environment: Ubuntu 24.04.5, gcc 13.3.0,
cmake 3.28.3, binutils 2.42.

## Headline result

**The compiler stage is deterministic; the build is not
path-independent.** Same-path repeats are byte-identical (R1 == R2,
6/6 artifacts). Builds from a different absolute path differ in all
6/6 artifacts, and the difference is exactly the embedded absolute
build/source path in DWARF debug info — no timestamps, no ordering
differences, no codegen differences. The standard prefix-map flags
eliminate the difference entirely (R4 == R1, 6/6 identical).
Toolchain changes (gcc 12, clang 18) change all artifacts, as expected.
The full `postfiatd` binary was **not** built end-to-end on this VM
and is labeled UNMEASURED below — attempted, not completed.

## Reproducibility matrix (measured)

Six artifacts per run: `ed25519.c.o`, `libed25519.a`,
`libsecp256k1.a`, `secp256k1.c.o`, `precomputed_ecmult.c.o`,
`precomputed_ecmult_gen.c.o`. Full digests in `outputs/subset-R*.log`
and `run-manifest.json`.

| Comparison | Result | Evidence |
|---|---|---|
| R1 vs R2 — same-path repeat (gcc 13) | **IDENTICAL 6/6** | `outputs/compare-R1-R2.log` |
| R1 vs R3 — different absolute paths (gcc 13) | **DIFFERENT 6/6** | `outputs/compare-R1-R3.log`, `outputs/diagnosis-R1-R3.log` |
| R1 vs R4 — different paths + prefix-map remediation (gcc 13) | **IDENTICAL 6/6** | `outputs/compare-R1-R4.log` |
| R1 vs R5 — gcc 12.4.0 vs gcc 13.3.0 | **DIFFERENT 6/6** (expected) | `outputs/compare-R1-R5.log` |
| R1 vs R6 — clang 18.1.3 vs gcc 13.3.0 | **DIFFERENT 6/6** (expected) | `outputs/compare-R1-R6.log` |
| R3 re-run (`R3diag`) vs R3 | **IDENTICAL 6/6** | `outputs/subset-R3diag.log` |

Canonical digests (R1, gcc 13.3.0, project Release flags):

| Artifact | SHA-256 |
|---|---|
| `ed25519/CMakeFiles/ed25519.dir/ed25519.c.o` | `457d75179198bd5a0c875de0b4d1b25f982cdb26ea03bb1a6be9306d71f77cbd` |
| `ed25519/output/Release/lib/libed25519.a` | `0dad7a8ff9be23d7508914c9ea4bbf31f90409b950668eb8ebe3c06e7659edf6` |
| `secp256k1/lib/libsecp256k1.a` | `46fb3aeeffe0b55becaab28d743e359add00697e0e4db76ba6e5094f6108a7ae` |
| `secp256k1/src/CMakeFiles/secp256k1.dir/secp256k1.c.o` | `da44af0e8e2ba5c391fa98b40b982b11b12a9b15678322b7421cfb3abe80f022` |
| `secp256k1/src/CMakeFiles/secp256k1_precomputed.dir/precomputed_ecmult.c.o` | `4f2db09b88156e13ead1c34f019164d7d3041e1cd5bb790bec967a1dc3d5454c` |
| `secp256k1/src/CMakeFiles/secp256k1_precomputed.dir/precomputed_ecmult_gen.c.o` | `56cc8461d5f6738e21e26d06dbfc472ba107a0e05691fec666be4ac3265f8e5d` |

## Diagnosis of the R1/R3 mismatch (embedded path only)

- Sizes identical for every artifact (e.g. `secp256k1.c.o`
  1,054,016 bytes in both runs; `libsecp256k1.a` 2,203,822 bytes).
- `cmp -l` on `secp256k1.c.o`: **15 differing bytes**, all octal
  `141` vs `142` — the single characters `a` vs `b` in
  `subset-src-a`/`subset-build-a` vs `subset-src-b`/`subset-build-b`.
- `readelf --debug-dump=info`: `DW_AT_comp_dir` is the absolute build
  directory (`.../work/subset-build-a/secp256k1/src`) and `DW_AT_name`
  is the absolute source path
  (`.../work/subset-src-a/external/secp256k1/src/secp256k1.c`); the
  `.debug_line` file table carries the same absolute source and include
  paths. `DW_AT_producer` records the compiler and flags, identical
  across runs.
- `ar tv`: all archive members dated `Jan 1 00:00 1970` — GNU ar
  deterministic mode, no archive timestamps.
- No build-date strings in any object; no `__DATE__`/`__TIME__`/
  `__TIMESTAMP__` anywhere in `src/` or `include/`.
- R4 proves the cause: mapping the B paths onto the A paths with
  `-ffile-prefix-map` / `-fdebug-prefix-map` / `-fmacro-prefix-map`
  (plus `SOURCE_DATE_EPOCH=1791651206`) makes all 6 digests identical
  to R1.

## Static-audit findings (severity-scored)

### F-1 — HIGH: Release builds embed the absolute build path via `-g`, with no path remapping

- Evidence: `cmake/RippledCompiler.cmake:107` adds `-g` for
  `CONFIG:Release`; the Dockerfile and `BUILD.md:401` both build
  Release. No `-ffile-prefix-map`, `-fdebug-prefix-map` or
  `-fmacro-prefix-map` appears anywhere in `CMakeLists.txt`, `cmake/`,
  `conanfile.py`, `conan/`, `BUILD.md` or `Dockerfile`
  (`outputs/static-audit.log` §3–4).
- Measured effect: R1 vs R3, 6/6 artifacts differ; diagnosis above.
- Remediation: add a fixed build path (or `-ffile-prefix-map=${CMAKE_SOURCE_DIR}=/postfiatd
  -ffile-prefix-map=${CMAKE_BINARY_DIR}=/postfiatd-build`) to the
  `common` interface target in `cmake/RippledCompiler.cmake`, and
  verify with this pack's harness (R4 shows the flags alone suffice).
  Cost: one CMake change; debug info stays usable, paths just become
  location-independent. Priority: first — it is the only measured
  cross-environment difference.

### F-2 — MEDIUM: `GIT_BRANCH` is baked into the binary and depends on the checkout, not the commit

- Evidence: `CMakeLists.txt:45-47` defines `GIT_BRANCH` from
  `git rev-parse --abbrev-ref HEAD` for every source file; it is
  printed by `src/xrpld/app/main/Main.cpp:519-520` (`--version`) and
  served over RPC by `src/xrpld/app/misc/NetworkOPs.cpp:2773-2774`
  (`server_info` → `git.branch`). Two checkouts of the same commit on
  differently-named branches produce different binaries; a tarball
  without `.git` produces a binary without the define at all.
  `GIT_COMMIT_HASH` (`CMakeLists.txt:37-39`, used in
  `src/libxrpl/protocol/BuildInfo.cpp:44-45` for DEBUG/SANITIZER
  builds, `Main.cpp:516-517`, `NetworkOPs.cpp:2770-2771`) is safe —
  it depends only on the commit.
- Measured effect: not directly measured (the subset libraries do not
  compile `Main.cpp`/`NetworkOPs.cpp`); flagged from the static audit
  and the build-system reading. The full-binary dimension is UNMEASURED.
- Remediation: stop embedding the branch name, or normalize it (e.g.
  only embed it when the checkout is on a branch whose name is pinned,
  or derive it from the commit only). At minimum, document that
  released binaries must be built from a detached HEAD at the pinned
  commit so `GIT_BRANCH` is constant.

### F-3 — MEDIUM: no `SOURCE_DATE_EPOCH` support anywhere in the build

- Evidence: no reference to `SOURCE_DATE_EPOCH` in `CMakeLists.txt`,
  `cmake/`, `conanfile.py`, `BUILD.md`, `Dockerfile` or `docs/build/`
  (`outputs/static-audit.log` §2). No `__DATE__`/`__TIME__` in the
  sources, so there is no timestamp leak *today* — but nothing pins
  the build date either, so any future timestamp use, or any
  dependency that embeds a date, has no normalization hook.
- Remediation: export `SOURCE_DATE_EPOCH` (commit time of the pinned
  commit, `1791651206`) in the Dockerfile and CI, and have CMake
  honor it for any generated file. This is a guard, not a fix for a
  measured defect.

### F-4 — LOW: linker selection is environment-dependent

- Evidence: `cmake/RippledCompiler.cmake:133-181` optionally switches
  the linker to mold, gold or lld (`use_mold` / `use_gold` /
  `use_lld`) based on what is installed. Different linkers produce
  different binaries from identical objects.
- Remediation: pin the linker in the release build configuration
  (default GNU ld on Linux) and record it in the build manifest.

### F-5 — LOW: `--build-id` is enabled on Linux (not a defect)

- Evidence: `cmake/RippledCompiler.cmake:111`
  (`-Wl,-z,relro,-z,now,--build-id`). A GNU build ID is a hash of the
  linked output, so it cannot introduce nondeterminism when the inputs
  are identical — but it does make any input difference visible in the
  final binary's note section. Recorded for completeness; no change
  needed.

### Cleared by the audit (no finding)

- **Source ordering**: `file(GLOB_RECURSE ... CONFIGURE_DEPENDS ...)`
  collects sources in `cmake/RippledCore.cmake:19,123,162,168`,
  `cmake/add_module.cmake:18`, `cmake/xrpl_add_test.cmake:6`. CMake
  orders GLOB results lexicographically since 3.6
  (cmake.org `file` documentation), so this is not an ordering risk
  on the project's minimum CMake 3.22.
- **`__FILE__`**: 52 occurrences in 20 files, all confined to the test
  framework (`include/xrpl/beast/unit_test.h:39`,
  `include/xrpl/beast/unit_test/suite.h:574,583`) and `src/test/*`.
  No production (non-test) `__FILE__` use. Test binaries built with
  `-Dtests=ON` would still embed paths via these macros — covered by
  the F-1 prefix-map fix.
- **Timestamps in code**: no `__DATE__`/`__TIME__`/`__TIMESTAMP__` in
  `src/` or `include/`; no `STRING(TIMESTAMP ...)` or `date` calls in
  `cmake/`, `scripts/`, `conan/` or `CMakeLists.txt`.
- **Archive determinism**: GNU ar/ranlib 2.42 in deterministic mode
  (member timestamps `Jan 1 00:00 1970`, observed); no explicit
  ar/ranlib settings needed.
- **Version string**: `src/libxrpl/protocol/BuildInfo.cpp:39`
  pins `versionString = "1.0.9"` in source; the version is read from
  that file by `cmake/RippledVersion.cmake`. Deterministic by
  construction.

## Toolchain variation (measured, expected to differ)

| Run | Compiler | Result vs R1 |
|---|---|---|
| R5 | gcc-12 12.4.0 | DIFFERENT 6/6 — `secp256k1.c.o` 1,051,568 bytes vs 1,054,016; 621,329 differing bytes |
| R6 | clang 18.1.3 | DIFFERENT 6/6 — `secp256k1.c.o` 1,410,872 bytes vs 1,054,016; 968,248 differing bytes; `DW_AT_producer` "Ubuntu clang version 18.1.3" |

This is the known reproducibility boundary: byte-identical output
requires the *same* compiler version (and the same flags). Any
reproducibility claim for postfiatd must name the exact toolchain —
gcc 13.3.0 here — and the release process must pin it (the Dockerfile
already pins gcc-13; the exact patch level should be recorded too).

## Dependency inventory (fetchability — measured)

All 15 direct pinned dependencies plus 5 resolved transitive ones had
their source URLs and SHA-256 taken from the exact recipe revisions
Conan resolved from Conan Center, and every source URL returned
HTTP 200 (redirects followed). Full table:
`fixtures/dependency-inventory.md`;
raw evidence: `outputs/deps-fetch-check.log`,
`outputs/deps-cached-recipes.txt`, `outputs/deps-url-status.txt`.

Notable: 7 pinned versions (grpc 1.50.1, soci 4.0.3, zlib 1.3.1,
protobuf 3.21.12, date 3.0.4, sqlite3 3.49.1, rocksdb 10.0.1) are no
longer listed in conan-center-index **master** `conandata.yml` — the
index has moved on — but the Conan Center remote still serves their
recipe revisions (proven: `conan install` downloaded
grpc/1.50.1 revision `12e06d669d66951b6a381d695cb715d0`), and every
upstream source tarball is still fetchable at its recorded URL. The
risk is drift, not breakage: a future rebuild that re-resolves against
master may pick different recipe revisions. Pinning the recipe
revisions (or vendoring the sources) removes it.

## UNMEASURED dimensions (labeled, not presented as measured)

1. **Full `postfiatd` binary reproducibility** — the complete
   `cmake --build` of the `postfiatd` target (link step, protobuf code
   generation, `GIT_BRANCH` embedding, Conan-built dependencies).
   Attempted for real with the Dockerfile's exact commands
   (`scripts/build_full.sh`): Conan 2.34.0 resolved and downloaded all
   recipes, downloaded 16 prebuilt binary packages, and built abseil
   and rocksdb 10.0.1 from source (no prebuilt binary matched gcc 13 /
   libstdc++11 for these). The first attempt then failed at the
   grpc/1.50.1 source step on a transient network timeout to Conan
   Center (`ReadTimeoutError`, read timeout=30) — not a build error;
   a retry was running at pack time and had reached the grpc build
   (~13%). See `outputs/full-build-status.md` for the exact state and
   the detached continuation that carries the attempt forward.
   No full-binary digest exists; none is claimed.
2. **Two independent full environments** (different distro/kernel) —
   both subset "clean-environment" builds ran on the same VM/kernel;
   only the absolute paths differed. True cross-machine reproduction
   of the full binary is unmeasured.
3. **Conan-built dependency reproducibility** — whether the Conan
   packages themselves (grpc, rocksdb, ...) rebuild byte-identically
   was not measured; only their recipe fetchability was.
4. **Test-binary (`-Dtests=ON`) reproducibility** — not built; the
   `__FILE__` uses in `src/test` would embed paths there too (covered
   by the F-1 fix in principle, not measured).
