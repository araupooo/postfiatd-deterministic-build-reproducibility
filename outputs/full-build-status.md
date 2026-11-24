# Full-build attempt — status at pack time

Pinned commit: `0085a1ff885d6a446369cf73a4430f75af22be55`.
Status timestamp: 2026-11-24 ~15:05 UTC (22:05 WIB).

## Outcome: UNMEASURED — attempted, not completed

The full `postfiatd` binary was **not** built end-to-end on the audit
VM. No full-binary digest exists and none is claimed. What follows is
the exact record of the attempt.

## What was attempted (Dockerfile's exact commands)

Conan 2.34.0 was installed in a venv; profile detected as gcc 13 /
libstdc++11 / Release. Then, from `work/build-full`:

```bash
conan install ../postfiatd-src --output-folder . --build missing \
  --settings build_type=Release --settings compiler.version=13 \
  --settings compiler.cppstd=20 --settings compiler.libcxx=libstdc++11
```

## Progress

- All recipes resolved and downloaded from Conan Center, including
  grpc/1.50.1 revision `12e06d669d66951b6a381d695cb715d0`.
- 16 prebuilt binary packages downloaded.
- abseil (grpc dependency) built from source — no prebuilt binary
  matched this configuration.
- rocksdb 10.0.1 built from source and packaged
  (`librocksdb.a`, package revision
  `f8f22517accbeb5f9f0a3e35e7719bf7`).
- **First attempt FAILED at grpc/1.50.1 (package 20 of 22), source
  step:** `ERROR: HTTPSConnectionPool(host='center2.conan.io',
  port=443): Max retries exceeded … ReadTimeoutError (read
  timeout=30)` — a transient network timeout to Conan Center, not a
  missing package or a build error. `conan install exit=1`.
- **Retry 1 started immediately** (same command, same Conan home —
  the cache resumes from the completed packages). It reached the grpc
  build (~91%) and then **died at 15:32 UTC on SIGTERM** (the tracked
  background session was terminated; the exact trigger was not
  established — no `conan install retry1 exit=` marker was written).
  The grpc build progress from that run was lost; the cache retains
  the completed rocksdb/abseil packages.
- **Driver misfire (caught and fixed):** the first detached
  continuation had a 20-minute wait cap and expired while retry 1 was
  still building, starting a second concurrent `conan install` on the
  same cache. It was caught within minutes and killed; no cache
  corruption was observed (both grpc build dirs were marked dirty and
  Conan rebuilds them).
- **Retry 2 is running** under a corrected detached driver
  (`work/continue-full-build.sh`, 300-minute wait, relaunched
  15:33 UTC, logging to `logs/full-build-detached.log`). It will run
  the install once more, then the Dockerfile's cmake configure and
  `cmake --build . -j 2`, and digest any `postfiatd` binary produced.
  Evidence excerpts: `outputs/conan-install-excerpt.log`.

## Continuation

A detached continuation (`work/continue-full-build.sh`, launched with
`setsid`/`nohup`, logging to `logs/full-build-detached.log`) carries
the attempt forward after this session ends: it waits for retry 1,
re-runs the install once more if needed, then runs the Dockerfile's
`cmake` configure (`-Dxrpld=ON -Dvalidator_keys=ON`) and
`cmake --build . -j 2`, and digests any `postfiatd` binary produced.
If it completes, the pack can be updated with the full-binary result;
until then the full-binary dimension stays UNMEASURED.

## Why it did not complete in the audit window

The Conan step alone builds abseil, grpc and protobuf from source
(plus rocksdb) because no prebuilt binaries matched gcc 13 /
libstdc++11 for these packages, and the VM has 1.5 shared CPUs and
~7.7 GB RAM. The subsequent `postfiatd` compile is ~1,000+ translation
units. The attempt is real and documented; the result is honestly
absent.
