#!/usr/bin/env bash
# Copy every file and folder an app's conversion reads or edits out of its pinned upstream image
# (apps/<app>/upstream.env) into tests/.upstream/<app>, laid out as in the image. A file or folder the image no
# longer has fails here.
#
#   tests/extract-upstream.sh <app> [image]     (default image: the one and digest in upstream.env)
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
app="${1:?usage: tests/extract-upstream.sh <app> [image]}"
# shellcheck disable=SC1090
. "$here/apps/$app/upstream.env"
image="${2:-$UPSTREAM_IMAGE:$UPSTREAM_VERSION@$UPSTREAM_DIGEST}"
out="$here/tests/.upstream/$app"
docker="${DOCKER:-docker}"

rm -rf "$out"
mkdir -p "$out"
cid="$($docker create "$image")"
trap '$docker rm "$cid" > /dev/null' EXIT

list="$(python3 -I -c '
import importlib.util, sys
spec = importlib.util.spec_from_file_location("app_convert", sys.argv[1])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
for rel in (*mod.UPSTREAM_FOLDERS, *mod.UPSTREAM_FILES): print(rel)' "$here/apps/$app/convert.py")"
status=0
while read -r rel; do
  # Through tar, so the copy belongs to whoever runs the tests (docker cp may run as root) and is writable.
  mkdir -p "$out/$(dirname "$rel")"
  if ! $docker cp "$cid:/$rel" - 2> /dev/null \
       | tar -x -C "$out/$(dirname "$rel")" --no-same-owner --no-same-permissions --mode=u+w 2> /dev/null \
     || [ ! -e "$out/$rel" ]; then
    echo "missing from $image: /$rel" >&2
    rm -rf "${out:?}/$rel"
    status=1
  fi
done <<< "$list"
exit "$status"
