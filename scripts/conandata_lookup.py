#!/usr/bin/env python3
"""Extract pinned-version source URL + SHA-256 from a conan-center-index
conandata.yml (handles both flat and nested `source:` layouts)."""
import sys, urllib.request, yaml

name, version, url = sys.argv[1], sys.argv[2], sys.argv[3]
req = urllib.request.Request(url, headers={"User-Agent": "postfiatd-repro-audit/1.0"})
try:
    with urllib.request.urlopen(req, timeout=60) as r:
        data = yaml.safe_load(r.read().decode("utf-8"))
except Exception as e:
    print(f"conandata fetch: FAILED ({e})")
    sys.exit(0)

sources = data.get("sources") or {}
entry = sources.get(version)
if entry is None:
    print(f"conandata fetch: OK")
    print(f"version {version}: NOT LISTED in current conandata.yml "
          f"(versions present: {', '.join(sorted(str(k) for k in sources))})")
    sys.exit(0)

# entry may be {url, sha256} or {source: {url, sha256}, ...}
node = entry.get("source", entry) if isinstance(entry, dict) else entry
u = node.get("url") if isinstance(node, dict) else None
s = node.get("sha256") if isinstance(node, dict) else None
if isinstance(u, list):
    u = u[0]
print("conandata fetch: OK")
print(f"recorded sha256: {s}")
print(f"source url: {u}")
sys.exit(0)
