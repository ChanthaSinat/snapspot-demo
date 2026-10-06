#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
flutter_bin="${FLUTTER_BIN:-/Users/chanthasinat/Develop/flutter/bin/flutter}"
if [[ -f mapbox.local.json ]]; then
  python3 - <<'CHECK'
import json
from pathlib import Path
try:
    token=json.loads(Path('mapbox.local.json').read_text()).get('ACCESS_TOKEN', '')
    assert isinstance(token,str) and token.startswith('pk.') and len(token)>10
except Exception:
    raise SystemExit('mapbox.local.json must contain ACCESS_TOKEN with a public pk. token. No token was printed.')
CHECK
  exec "$flutter_bin" run --dart-define-from-file=mapbox.local.json "$@"
else
  exec "$flutter_bin" run "$@"
fi
