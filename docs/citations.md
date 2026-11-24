# Primary sources

## Reproducible Builds project

- "Build path" — https://reproducible-builds.org/docs/build-path/
  (fetched 2026-11-24): compilers record the source path in debug
  info; `-fdebug-prefix-map`, `-fmacro-prefix-map`,
  `-ffile-prefix-map` are the documented workarounds.
- "SOURCE_DATE_EPOCH" — https://reproducible-builds.org/docs/source-date-epoch/
  (fetched 2026-11-24) and the specification
  https://reproducible-builds.org/specs/source-date-epoch/: the
  standardized build-date variable; CMake `STRING(TIMESTAMP ...)`
  respects it since CMake 3.8.
- Documentation index — https://reproducible-builds.org/docs/
  (fetched 2026-11-24).

## Compiler / linker documentation

- GCC, "Debugging Options" —
  https://gcc.gnu.org/onlinedocs/gcc/Debugging-Options.html
  (fetched 2026-11-24): `-g` produces debugging information in the
  native (DWARF) format; `-fdebug-prefix-map=old=new` records debug
  info "as if the files resided in directory *new*… This can give
  more reproducible builds, which are location independent".
- GCC, "Developer Options" —
  https://gcc.gnu.org/onlinedocs/gcc/Developer-Options.html
  (fetched 2026-11-24): background on compiler developer options.
- GNU ld `--build-id` — `ld --help` on the audit machine (binutils
  2.42) lists `--build-id[=STYLE]  Generate build ID note`; a build ID
  is a hash of the linked output, so it cannot introduce
  nondeterminism when the inputs are identical.
- GNU ar deterministic mode — no explicit setting in the project;
  observed directly: `ar tv` shows all archive members dated
  `Jan 1 00:00 1970` (`outputs/diagnosis-R1-R3.log`).

## Build-system documentation

- CMake, `file` command —
  https://cmake.org/cmake/help/latest/command/file.html
  (fetched 2026-11-24): "Changed in version 3.6: The results will be
  ordered lexicographically" (`file(GLOB ...)`).

## Pinned postfiatd documentation (commit 0085a1ff, blobs verified against the GitHub API tree)

- `BUILD.md` — blob `60e6c0001abe7566cc6458e70df5f00f61516699`:
  Python 3.11+, Conan 2.17+, CMake 3.22+, GCC 12 / Clang 16;
  canonical `conan install` + CMake Release build; XRPLF
  conan-center-index fork and `xrplf` remote for patched recipes.
- `Dockerfile` — blob `71c0296dea3ab7bd640a2f54da735eccc266b4f4`:
  Ubuntu 24.04, gcc-13, cmake 3.25.1 from the Kitware tarball, Conan
  via pipx, `conan install .. --build missing` (Release,
  compiler.version=13, cppstd=20, libstdc++11),
  `cmake -DCMAKE_BUILD_TYPE=Release -Dxrpld=ON -Dvalidator_keys=ON`.
- `conanfile.py` — blob `bff4c93aa35cabfb57ae0216078b7fb746ee2aa0`:
  all pinned dependency versions.
- `cmake/RippledCompiler.cmake` — blob `bc3a62a48c48b34f402de240b905858171630362`:
  `-g` for Release (`:107`), `--build-id` (`:111`), optional
  mold/gold/lld linker selection (`:133-181`).
- `CMakeLists.txt` — blob `c71fb6859903404297ae2744eefda803a25b9ab6`:
  `GIT_COMMIT_HASH` / `GIT_BRANCH` defines (`:37-47`).
- `src/libxrpl/protocol/BuildInfo.cpp` — blob `8685f9ccf0ec0b6b79d69a641a66fb439c25a860`:
  `versionString = "1.0.9"` (`:39`), `GIT_COMMIT_HASH` use (`:44-45`).
- `src/xrpld/app/main/Main.cpp` — blob `24ca068579113cd8f89d019613d8223a252936a4`:
  `GIT_COMMIT_HASH` / `GIT_BRANCH` printing (`:516-520`).
- `src/xrpld/app/misc/NetworkOPs.cpp` — blob `57331a855843f0a528289fb3a96f3251926a3aa5`:
  `server_info` git hash/branch (`:2767-2774`).
- `cmake/RippledCore.cmake` — blob `0198b5fbc25d8d382f0329fac6b4e4954da7a194`:
  `file(GLOB_RECURSE ...)` source collection (`:19,123,162,168`).

All blob SHAs and sizes were verified against the GitHub API tree for
commit `0085a1ff885d6a446369cf73a4430f75af22be55` — see
`outputs/blob-verification.txt` (15/15 agree).
