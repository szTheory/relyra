#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

package_dir="/tmp/relyra-package-check"

if [ ! -f "demo/ledger_loop/mix.exs" ]; then
  echo "demo package exclusion: missing demo/ledger_loop/mix.exs" >&2
  exit 1
fi

if ! grep -Fq '{:relyra, path: "../.."}' demo/ledger_loop/mix.exs; then
  echo "demo package exclusion: demo app does not use the local Relyra path dependency" >&2
  exit 1
fi

rm -rf /tmp/relyra-package-check
mix hex.build --unpack --output /tmp/relyra-package-check >/tmp/relyra-package-check.log

demo_path="$(find /tmp/relyra-package-check -path '*/demo/*' -print -quit)"

if [ -n "$demo_path" ]; then
  echo "demo package exclusion: found demo path in unpacked package: $demo_path" >&2
  exit 1
fi

echo "demo package exclusion: ok"
