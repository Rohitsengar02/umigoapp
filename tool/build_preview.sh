#!/usr/bin/env bash
# Builds a slim, relative-path web preview into $1 (default build/preview)
set -e
OUT=${1:-build/preview}
flutter build web --release --no-web-resources-cdn
rm -rf "$OUT"; cp -r build/web "$OUT"; cd "$OUT"
find . \( -name '*.symbols' -o -name '*.map' -o -name 'skwasm*' -o -name 'wimp*' -o -name 'flutter_service_worker.js' \) -delete
sed -i 's#<base href="/">#<base href="./">#' index.html
python3 - <<'PY'
p='flutter_bootstrap.js'; s=open(p).read(); i=s.rindex('_flutter.loader.load({')
open(p,'w').write(s[:i]+'_flutter.loader.load({});\n')
PY
