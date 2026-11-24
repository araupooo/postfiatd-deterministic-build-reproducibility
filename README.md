# Postfiatd Deterministic Build Reproducibility Evidence Pack

An audit of whether `postfiatd` produces byte-identical artifacts across
repeated and independent clean builds, at pinned commit
`0085a1ff885d6a446369cf73a4430f75af22be55`
(2026-10-10, "Merge pull request #50 … hotfix/upstream-hardening-1.0.9").

## Headline results

- **Same-path repeats are byte-identical: 6/6 artifacts** (R1 == R2).
- **Different absolute build paths differ in 6/6 artifacts** (R1 vs R3) —
  and the difference is exactly the embedded absolute build/source path
  in DWARF debug info: identical sizes, 15 differing bytes in
  `secp256k1.c.o`, all single-character path substitutions; no
  timestamps, no ordering differences.
- **The standard fix works: prefix-map flags restore byte-identical
  output, 6/6** (R1 == R4).
- **Toolchain changes change everything, as expected:** gcc 12 vs 13
  and clang 18 vs gcc 13 each differ in 6/6 artifacts (R5, R6).
- **Full `postfiatd` binary: UNMEASURED.** The full build was attempted
  for real with the Dockerfile's exact commands; the Conan dependency
  step was still running / retrying at pack time (see
  `outputs/full-build-status.md`). No full-binary digest is claimed.
- Static audit: no `__DATE__`/`__TIME__` in the sources, no
  `SOURCE_DATE_EPOCH` support, no prefix-map flags, `-g` in Release
  builds, and `GIT_BRANCH` baked into the binary from the checkout's
  branch name. Full findings: `docs/findings-report.md`.

## Pinned environment

Ubuntu 24.04.5, gcc 13.3.0, cmake 3.28.3, binutils 2.42, Conan 2.34.0.
Reference environment (pinned `Dockerfile`): Ubuntu 24.04, gcc-13,
cmake 3.25.1, Conan via pipx.

## Contents

- `docs/methodology.md` — what was measured, what was not, and how.
- `docs/findings-report.md` — severity-scored findings, remediation,
  dependency inventory notes, unmeasured dimensions.
- `docs/decision-memo.md` — the reproducibility decision, with primary
  sources (Reproducible Builds, GCC, CMake, pinned postfiatd docs).
- `docs/claim-evidence-index.md` — every claim → its script and
  unedited log.
- `docs/citations.md` — primary sources.
- `outputs/` — unedited logs, digest comparisons, mismatch diagnosis,
  dependency fetch checks, blob verification.
- `scripts/` — the full harness (see Reproduce).
- `fixtures/dependency-inventory.md` — every pinned dependency with
  source URL, SHA-256 and live fetch status, plus the toolchain
  inventory.
- `run-manifest.json` — machine-readable run record.
- `SHA256SUMS` — full SHA-256 digests of every pack file
  (`scripts/verify_digests.sh`).

## Reproduce

```bash
bash scripts/run_all.sh                      # subset matrix + audits + dep checks (~3 min)
bash scripts/run_all.sh --with-full-build    # also attempts the full binary build (hours)
bash scripts/verify_digests.sh               # sha256sum -c SHA256SUMS
```

`run_all.sh` clones the pinned commit itself (or reuse a local tree
with `POSTFIATD_SRC` / `POSTFIATD_SRC2`). The subset matrix builds the
two self-contained vendored libraries (`external/secp256k1`,
`external/ed25519-donna`) with the project's own Release flags
(`-O3 -DNDEBUG -g -fstack-protector`) in six runs: same-path repeat,
different absolute paths, prefix-map remediation, gcc-12, and clang.

The full build (`scripts/build_full.sh`) follows the pinned
`Dockerfile` exactly: `conan install .. --build missing` (Release,
compiler.version=13, cppstd=20, libstdc++11), CMake configure
(`-Dxrpld=ON -Dvalidator_keys=ON`), `cmake --build`. It needs Conan
>= 2.17, CMake >= 3.22, gcc >= 12, and several hours on a small
machine — the Conan step builds abseil/grpc/rocksdb from source when
no prebuilt binary matches.
