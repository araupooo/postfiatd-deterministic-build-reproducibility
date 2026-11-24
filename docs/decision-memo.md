# Decision memo — is the postfiatd build reproducible, and what would make it so?

Pinned commit: `0085a1ff885d6a446369cf73a4430f75af22be55`
(2026-10-10). Audit date: 2026-11-24.

## Decision

**Not reproducible as documented today, for one measured reason and
two structural ones — but the measured reason has a proven one-line
fix, and nothing else in the audit blocks reproducibility.**

1. **Measured: the build embeds the absolute build path.** Release
   builds add `-g`, and no prefix-map flag is set anywhere. Two builds
   of the same commit from different directories differ in every
   artifact (6/6 in the subset matrix). The fix — `-ffile-prefix-map`
   for the source and build directories — was tested in this audit and
   restores byte-identical output (R4 == R1, 6/6).
2. **Structural: the branch name is baked into the binary.**
   `GIT_BRANCH` comes from the checkout's branch, not the commit, so
   identical commits on different branches differ. This was not
   measured end-to-end (the full binary was not built), but it follows
   directly from `CMakeLists.txt:45-47` and the three use sites.
3. **Structural: the toolchain is pinned only loosely.** The Dockerfile
   pins gcc-13 and the build docs require GCC 12+, but the exact
   compiler patch level, the exact CMake version (Dockerfile builds
   3.25.1 from source; this audit used 3.28.3), and the Conan recipe
   revisions are not recorded in a lockfile that a rebuilder can
   replay. Toolchain variation was measured to change every artifact
   (gcc 12 vs 13; clang 18 vs gcc 13).

## What the primary sources say

- **Reproducible Builds, "Build path"**
  (https://reproducible-builds.org/docs/build-path/): "Some tools will
  record the path of the source files in their output. Most compilers
  write the path of the source in the debug information in order to
  locate the associated source files." The documented workarounds are
  `-fdebug-prefix-map=OLD=NEW`, `-fmacro-prefix-map=OLD=NEW`, and
  `-ffile-prefix-map=OLD=NEW` as an alias for both. This is exactly
  what the audit measured (DWARF `DW_AT_comp_dir` / `DW_AT_name`) and
  exactly what R4 verified as a fix.
- **Reproducible Builds, "SOURCE_DATE_EPOCH"**
  (https://reproducible-builds.org/docs/source-date-epoch/ and the
  specification at https://reproducible-builds.org/specs/source-date-epoch/):
  the standardized variable distributions set centrally so build
  tools produce reproducible output; CMake's `STRING(TIMESTAMP ...)`
  has respected it since CMake 3.8. postfiatd does not consume it
  anywhere — no defect today (no timestamp macros in the sources),
  but no normalization hook either.
- **GCC, "Debugging Options"**
  (https://gcc.gnu.org/onlinedocs/gcc/Debugging-Options.html):
  `-fdebug-prefix-map=old=new` — "When compiling files residing in
  directory *old*, record debugging information describing them as if
  the files resided in directory *new* instead. … This can give more
  reproducible builds, which are location independent". The same page
  documents `-g` as producing debugging information in the native
  (DWARF) format — the mechanism by which the path enters the object.
- **CMake, `file` command**
  (https://cmake.org/cmake/help/latest/command/file.html): "Changed in
  version 3.6: The results will be ordered lexicographically." The
  project's `file(GLOB_RECURSE ...)` source collection is therefore
  not an ordering risk on the project's minimum CMake 3.22.
- **Pinned postfiatd build documentation** (`BUILD.md` at the pinned
  commit): requires Python 3.11+, Conan 2.17+, CMake 3.22+, GCC 12 /
  Clang 16; the canonical build is `conan install` followed by CMake
  with `-DCMAKE_BUILD_TYPE=Release -Dxrpld=ON`. The pinned
  `Dockerfile` fixes the reference environment to Ubuntu 24.04,
  gcc-13, cmake 3.25.1 (built from the Kitware tarball), Conan via
  pipx, `conan install .. --build missing` with
  `build_type=Release, compiler.version=13, compiler.cppstd=20,
  compiler.libcxx=libstdc++11`. Neither document mentions
  reproducibility, `SOURCE_DATE_EPOCH`, or path remapping.

## Recommendation

Adopt the following, in order, and re-run this pack's harness
(`scripts/run_all.sh`) after each step to confirm the matrix stays green:

1. **Add prefix-map flags to the release build** (fixes F-1, the only
   measured defect): in `cmake/RippledCompiler.cmake`, on the `common`
   interface target, add
   `-ffile-prefix-map=${CMAKE_SOURCE_DIR}=/postfiatd` and
   `-ffile-prefix-map=${CMAKE_BINARY_DIR}=/postfiatd-build`
   (or a single fixed build path enforced by the Dockerfile/CI).
   Expected result: two Release builds from different directories
   produce identical `postfiatd` binaries.
2. **Remove or normalize `GIT_BRANCH`** (fixes F-2): embed the commit
   hash only, or build releases from a detached HEAD at the pinned
   commit so the branch string is constant.
3. **Record the exact toolchain and recipe revisions** (fixes F-3/F-4
   and the drift risk): commit the Conan lockfile, record the exact
   compiler, CMake and binutils versions in the release manifest, pin
   the linker to GNU ld, and export
   `SOURCE_DATE_EPOCH=<commit time>` in the Dockerfile/CI.
4. **Publish a reproducibility check in CI**: run this pack's
   `scripts/run_all.sh --with-full-build` twice from different
   directories on the release toolchain and compare the `postfiatd`
   binary digests. Until that check exists and passes, no release
   should be described as reproducible — only as "deterministic on a
   fixed path with a fixed toolchain", which is what this audit
   measured.

## What this memo does not claim

- It does not claim the full `postfiatd` binary is reproducible: the
  full build was attempted but not completed on the audit VM (see
  `docs/findings-report.md`, "UNMEASURED dimensions", and
  `outputs/full-build-status.md`). The claims above cover the measured
  subset (the vendored libraries, compiled with the project's Release
  flags) and the static audit of the full build system.
- It does not claim prefix-map flags fix the link step or protobuf
  generation — only that they fix the measured object-file difference.
  The CI check in recommendation 4 is the control for the rest.
