# Methodology

## Audited commit

- Repository: `postfiatorg/postfiatd`
- Pinned commit: `0085a1ff885d6a446369cf73a4430f75af22be55`
- Commit date: 2026-10-10 18:53:26 +0200
- Commit message: `Merge pull request #50 from postfiatorg/hotfix/upstream-hardening-1.0.9`
- Commit timestamp as `SOURCE_DATE_EPOCH`: `1791651206`
- HEAD was resolved with `git ls-remote` (the GitHub API was rate-limited
  for unauthenticated requests from the shared egress IP at first check);
  the same commit was already pinned by the two preceding evidence packs.
  All 15 key files cited in this pack were verified blob-by-blob: the local
  `git hash-object` SHA and size agree with the GitHub API tree for the
  pinned commit — see `outputs/blob-verification.txt` (15/15 agree).
  No cited line number comes from a raw-file web fetch; every line was
  verified with `grep -n` on the local checkout of the pinned commit.

## Environment in which the measurements were taken

- Host: Linux `htch-runtime` 7.0.0-44-generic, x86_64, Ubuntu 24.04.5 LTS
- CPUs: 4 vCPUs visible, 1.5 shared CPUs allocated; RAM ~7.7 GB
  (~0.5–0.9 GB free while the dependency builds ran); disk 90 GB free
- Toolchain (measured, `scripts/build_subset.sh` logs record each):
  - gcc 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04.1), g++ 13.3.0
  - gcc-12 12.4.0 and clang 18.1.3 installed during the audit for the
    toolchain-variation runs (R5/R6)
  - cmake 3.28.3, GNU ld 2.42, GNU ar/ranlib 2.42
  - Python 3.12.3, Conan 2.34.0 (installed in a venv for the audit)
  - System OpenSSL 3.0.13 (`libssl-dev`), used only by the ed25519-donna
    subset build
- Reference build environment (from the pinned `Dockerfile`): Ubuntu
  24.04, gcc-13/g++-13, cmake 3.25.1 built from the Kitware tarball,
  Conan via pipx, `conan install .. --build missing` with
  `build_type=Release, compiler.version=13, compiler.cppstd=20,
  compiler.libcxx=libstdc++11`, then
  `cmake -DCMAKE_BUILD_TYPE=Release -Dxrpld=ON -Dvalidator_keys=ON ..`
  and `cmake --build . -j $(nproc)`. Note the local cmake is 3.28.3, not
  the Dockerfile's 3.25.1 — a documented deviation, not a hidden one.

## What was measured, and what was not

The full `postfiatd` binary is a rippled fork: ~1,000+ translation units
plus Conan-managed dependencies (grpc, rocksdb, boost, protobuf, ...).
A full build on this VM needs the whole Conan set built from source
(no prebuilt binary matched this configuration for abseil/grpc/rocksdb)
and then a multi-hour compile on 1.5 shared CPUs. The full build was
attempted for real (`scripts/build_full.sh`, Dockerfile's exact commands;
see `outputs/full-build-status.md`) and did not complete in the audit
window — the Conan dependency step failed once on a network timeout
to Conan Center and was retrying at pack time; it is recorded here as
**UNMEASURED — attempted, not completed** — not as a result.

What *was* measured, on the real pinned source, with the project's
own Release flags:

1. **Static build-system audit** (`scripts/audit_build_system.sh`,
   `outputs/static-audit.log`): timestamp macros, `SOURCE_DATE_EPOCH`
   handling, path-remapping flags, `-g` in Release, `--build-id`,
   git-metadata embedding, `__FILE__` uses, `file(GLOB...)` ordering,
   linker selection, date calls in build scripts.
2. **Subset reproducibility matrix** (`scripts/build_subset.sh`): the two
   self-contained vendored libraries that the top-level build compiles
   in-tree — `external/secp256k1` (`libsecp256k1.a`, 3 objects) and
   `external/ed25519-donna` (`libed25519.a`, 1 object) — built with
   project-equivalent Release flags (`-O3 -DNDEBUG -g -fstack-protector
   -Wall`, matching `cmake/RippledCompiler.cmake`, which adds `-g` to
   Release builds). Six runs, six artifacts each:

   | Run | Source | Build dir | Compiler | Flags | Purpose |
   |-----|--------|-----------|----------|-------|---------|
   | R1 | copy A | build-a | gcc 13.3.0 | project Release | baseline |
   | R2 | copy A | build-a (cleaned) | gcc 13.3.0 | project Release | same-path repeat |
   | R3 | copy B (different absolute path) | build-b | gcc 13.3.0 | project Release | independent clean-environment build |
   | R4 | copy B | build-b | gcc 13.3.0 | project Release + `-ffile-prefix-map`/`-fdebug-prefix-map`/`-fmacro-prefix-map` mapping B paths onto A paths, `SOURCE_DATE_EPOCH=1791651206` | remediation probe |
   | R5 | copy A | build-gcc12 | gcc-12 12.4.0 | project Release | toolchain-version variation |
   | R6 | copy A | build-clang | clang 18.1.3 | project Release | toolchain-vendor variation |

   "Independent clean-environment build" on this single VM means a
   separate source copy at a different absolute path and a separate
   build directory — it tests embedded-path sensitivity, not kernel or
   distro independence. Both runs shared the same VM, kernel and
   toolchain installation. That limitation is stated here, not hidden.
3. **Byte comparison and diagnosis** (`scripts/compare_runs.sh`,
   `outputs/compare-*.log`, `outputs/diagnosis-R1-R3.log`): per-artifact
   SHA-256 digests (full 64 hex chars), `cmp -l` byte counts,
   `readelf --debug-dump=info` (DWARF `DW_AT_comp_dir` / `DW_AT_name`),
   `strings` diffs, `ar tv` member timestamps.
4. **Dependency/toolchain inventory with fetchability**
   (`scripts/check_deps_fetchability.sh`,
   `outputs/deps-fetch-check.log`, `outputs/deps-cached-recipes.txt`,
   `outputs/deps-url-status.txt`, `fixtures/dependency-inventory.md`):
   every version pinned in `conanfile.py`, its source URL and SHA-256
   taken from the exact recipe revision Conan resolved from Conan
   Center, and a live fetch check (HTTP status, redirects followed) for
   each URL.

## What the subset does and does not prove

- It proves the **compiler stage** is deterministic for real postfiatd
  sources when the build path is fixed (R1 == R2, 6/6 artifacts), and
  proves the **only** cross-path difference in these artifacts is the
  embedded absolute build/source path (R1 vs R3: 6/6 differ, diagnosed
  to 15 differing bytes in `secp256k1.c.o`, all single-character
  path substitutions; identical sizes; `ar` member timestamps
  `Jan 1 00:00 1970`).
- It proves the **remediation works**: R4 == R1, 6/6 artifacts
  identical, with prefix-map flags alone.
- It does **not** prove the full `postfiatd` binary is reproducible:
  the link step, protobuf code generation, the `GIT_BRANCH` embedding
  in `Main.cpp`/`NetworkOPs.cpp`, and the Conan-built dependencies were
  not exercised end-to-end. Those dimensions are labeled UNMEASURED in
  the findings report, with the static-audit evidence for each.

## Reproduce

```bash
scripts/run_all.sh                 # subset matrix + audits + dep checks
scripts/run_all.sh --with-full-build   # also attempts the full binary build
scripts/verify_digests.sh          # sha256sum -c SHA256SUMS
```

`run_all.sh` clones the pinned commit itself (or reuse a local tree with
`POSTFIATD_SRC` / `POSTFIATD_SRC2`). The subset matrix takes ~3 minutes
on this class of machine; the full build takes hours. The `R3diag`
rebuild in `outputs/subset-R3diag.log` re-ran R3 from scratch and
reproduced R3's six digests exactly — a second confirmation of
same-path repeatability.

A fresh-clone-style reproduction was run before publication: the pack
was copied to a fresh temp dir, its scripts stripped of executable bits
(as a plain `git clone` would deliver them), and `bash scripts/run_all.sh`
was executed there. It exited 0, `bash scripts/verify_digests.sh` passed
40/40, and every comparison matched this pack's results (R1==R2 IDENTICAL,
R1!=R3 DIFFERENT 6/6, R1==R4 IDENTICAL, R1!=R5 DIFFERENT, R1!=R6
DIFFERENT). Details: `outputs/fresh-clone-reproduction.log`. Three
earlier reproduction attempts caught real defects in `run_all.sh`
(missing executable bits; SHA256SUMS regenerated before the manifest
was written; direct invocation of helper scripts, which fails on clones
without executable bits) — all fixed (helpers are now invoked via
`bash scripts/...`), and the final run is clean end-to-end.
