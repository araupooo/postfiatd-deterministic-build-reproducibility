#!/usr/bin/env bash
# audit_build_system.sh — static determinism audit of the pinned postfiatd
# build system. Prints every check with the exact file:line evidence.
# Usage: audit_build_system.sh <source-dir>
# Output goes to stdout (caller redirects to an unedited log).
set -uo pipefail
SRC="${1:?source dir required}"
echo "=== static build-system determinism audit ==="
echo "source: ${SRC}"
echo "pinned HEAD: $(git -C "${SRC}" rev-parse HEAD 2>/dev/null || echo UNKNOWN)"
echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
cd "${SRC}"

section() { echo; echo "--- $1 ---"; }

section "1. __DATE__ / __TIME__ / __TIMESTAMP__ in C/C++ sources (classic timestamp embedding)"
if grep -rn "__DATE__\|__TIME__\|__TIMESTAMP__" src/ include/ --include='*.cpp' --include='*.h' --include='*.c' 2>/dev/null; then
  echo "FINDING: timestamp macros present (see above)"
else
  echo "OK: no __DATE__/__TIME__/__TIMESTAMP__ in src/ or include/"
fi

section "2. SOURCE_DATE_EPOCH handling anywhere in build files/docs"
if grep -rn "SOURCE_DATE_EPOCH" CMakeLists.txt cmake/ conanfile.py BUILD.md Dockerfile docs/build/ 2>/dev/null; then
  echo "FINDING: SOURCE_DATE_EPOCH referenced (see above)"
else
  echo "OK(absent): no SOURCE_DATE_EPOCH handling in CMakeLists.txt, cmake/, conanfile.py, BUILD.md, Dockerfile, docs/build/"
fi

section "3. Path-remapping flags (-ffile-prefix-map / -fdebug-prefix-map / -fmacro-prefix-map)"
if grep -rn "ffile-prefix-map\|fdebug-prefix-map\|fmacro-prefix-map\|ffile_prefix_map" CMakeLists.txt cmake/ conanfile.py conan/ BUILD.md Dockerfile 2>/dev/null; then
  echo "FINDING: prefix-map flags present (see above)"
else
  echo "OK(absent): no -ffile-prefix-map / -fdebug-prefix-map / -fmacro-prefix-map in build files"
fi

section "4. Debug info in Release builds (-g) — embeds compilation directory in DWARF"
grep -n -- "-g" cmake/RippledCompiler.cmake || echo "no -g flag found in cmake/RippledCompiler.cmake"
grep -rn "CMAKE_BUILD_TYPE.*Release\|Release.*-g" BUILD.md Dockerfile | head -5

section "5. Linker build-id flag"
grep -rn "build-id" cmake/ CMakeLists.txt || echo "no --build-id flag found"

section "6. Git metadata embedded at configure time (GIT_COMMIT_HASH / GIT_BRANCH)"
grep -n "GIT_COMMIT_HASH\|GIT_BRANCH" CMakeLists.txt
echo "-- uses in sources:"
grep -rn "GIT_COMMIT_HASH\|GIT_BRANCH" src/ include/ --include='*.cpp' --include='*.h'

section "7. __FILE__ uses (embeds the path as passed to the compiler)"
echo "files using __FILE__: $(grep -rln '__FILE__' src/ include/ --include='*.cpp' --include='*.h' | wc -l)"
echo "occurrences: $(grep -rn '__FILE__' src/ include/ --include='*.cpp' --include='*.h' | wc -l)"
grep -rn '__FILE__' src/ include/ --include='*.cpp' --include='*.h' | head -10

section "8. file(GLOB...) source collection (CMake sorts GLOB results lexicographically since 3.6)"
grep -rn "file(GLOB" cmake/ CMakeLists.txt

section "9. Linker selection (mold/gold/lld optional — environment-dependent linker changes output)"
grep -n "use_mold\|use_gold\|use_lld\|fuse-ld" cmake/RippledCompiler.cmake | head -12

section "10. date/time calls in build scripts (cmake/, scripts/, conan/)"
grep -rn "STRING(TIMESTAMP\|TIMESTAMP\|execute_process.*date\|COMMAND date" cmake/ scripts/ conan/ CMakeLists.txt 2>/dev/null | head -10 || echo "none found"

section "11. Version string source (BuildInfo.cpp)"
grep -n "versionString" src/libxrpl/protocol/BuildInfo.cpp | head -3

section "12. Archive determinism: ar/ranlib invocation"
grep -rn "CMAKE_AR\|CMAKE_RANLIB\|CMAKE_ARCHIVE" cmake/ CMakeLists.txt | head -5 || echo "no explicit ar/ranlib settings (CMake + binutils defaults apply)"

echo
echo "=== static audit done ==="
