#!/usr/bin/env bash
# Build once (npm tarball + PyPI sdist/wheel), verify, clean-env smoke.
# Leaves gruncellka-porto-features-*.tgz and dist/ for publish upload.
# Run: ./scripts/release/verify_artifact.sh or make artifact
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if [ -f venv/bin/activate ]; then
    # shellcheck source=/dev/null
    . venv/bin/activate
elif [ -f .venv/bin/activate ]; then
    # shellcheck source=/dev/null
    . .venv/bin/activate
fi

rm -f gruncellka-porto-features-*.tgz
rm -rf dist artifact-smoke-npm artifact-smoke-pypi dist-test build *.egg-info

echo "=== Build npm tarball ==="
npm pack --silent
TARBALL="$(ls -t gruncellka-porto-features-*.tgz 2>/dev/null | head -1)"
test -n "$TARBALL" || { echo "No tarball produced"; exit 1; }
echo "Tarball: $TARBALL"

echo "=== npm package contract ==="
LIST="$(tar -tzf "$TARBALL")"
echo "$LIST" | grep -q 'package/porto_features/features/' || {
    echo "FAIL: missing package/porto_features/features/"
    exit 1
}
echo "$LIST" | grep -q 'package/porto_features/fixtures/' || {
    echo "FAIL: missing package/porto_features/fixtures/"
    exit 1
}
for forbidden in "package/docs/" "package/scripts/" "package/.cursor/"; do
    if echo "$LIST" | grep -qF "$forbidden"; then
        echo "FAIL: npm package contains forbidden path: $forbidden"
        echo "$LIST" | grep -F "$forbidden" || true
        exit 1
    fi
done
echo "npm tarball structure OK"

echo "=== npm clean-env smoke ==="
TESTDIR="${ROOT}/artifact-smoke-npm"
rm -rf "$TESTDIR"
mkdir -p "$TESTDIR"
cd "$TESTDIR"
npm init -y >/dev/null
npm install --silent "${ROOT}/${TARBALL}"
npm install --silent --save-dev typescript
node -e "
const pkg = require('@gruncellka/porto-features');
const fs = require('fs');
const path = require('path');
const pdir = path.join(process.cwd(), 'node_modules/@gruncellka/porto-features/porto_features');
const sdkFeatures = path.join(pdir, 'features/sdk');
const hasPy = (dir) => {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const e of entries) {
    if (e.name.endsWith('.py')) return true;
    if (e.isDirectory() && hasPy(path.join(dir, e.name))) return true;
  }
  return false;
};
if (hasPy(pdir)) { console.error('FAIL: .py file in npm package'); process.exit(1); }
if (!fs.existsSync(path.join(pdir, 'errors.json'))) { console.error('FAIL: errors.json missing'); process.exit(1); }
if (!fs.existsSync(sdkFeatures)) { console.error('FAIL: features/sdk/ missing'); process.exit(1); }
console.log('require() OK, version:', pkg.version);
"
cat > smoke.ts <<'TS'
import { version } from '@gruncellka/porto-features';
const v: string = version;
console.log(v);
TS
npx tsc --ignoreConfig --noEmit --strict --target ES2020 --module commonjs smoke.ts
cd "$ROOT"
rm -rf "$TESTDIR"
echo "npm smoke OK (tarball kept: $TARBALL)"

echo ""
echo "=== Build PyPI sdist + wheel ==="
python3 -m pip install -q build
python3 -m build
WHEEL="$(ls -t dist/gruncellka_porto_features-*.whl 2>/dev/null | head -1)"
SDIST="$(ls -t dist/gruncellka_porto_features-*.tar.gz 2>/dev/null | head -1)"
test -n "$WHEEL" || { echo "no wheel in dist/"; exit 1; }
test -n "$SDIST" || { echo "no sdist in dist/"; exit 1; }
echo "Wheel: $WHEEL"
echo "Sdist: $SDIST"

echo "=== wheel contract ==="
WHEEL_LIST="$(python3 -m zipfile -l "$WHEEL")"
for forbidden in "docs/" "scripts/" ".cursor/" "gherlint.toml"; do
    if echo "$WHEEL_LIST" | grep -qF "$forbidden"; then
        echo "FAIL: PyPI wheel contains forbidden path: $forbidden"
        echo "$WHEEL_LIST" | grep -F "$forbidden" || true
        exit 1
    fi
done
echo "wheel structure OK"

echo "=== PyPI clean-env smoke ==="
PYDIR="${ROOT}/artifact-smoke-pypi"
rm -rf "$PYDIR" && mkdir -p "$PYDIR"
python3 -m pip install -q --force-reinstall "$WHEEL"
cd "$PYDIR"
python3 -c "
from pathlib import Path
import porto_features
root = Path(porto_features.__file__).parent
features = root / 'features'
fixtures = root / 'fixtures'
errors = root / 'errors.json'
assert features.exists(), 'features/ missing'
assert fixtures.exists(), 'fixtures/ missing'
assert errors.is_file(), 'errors.json missing'
assert list(features.rglob('*.feature')), 'no .feature files'
assert list(fixtures.rglob('*.json')), 'no .json in fixtures/'
print('porto_features import OK')
"
cd "$ROOT"
rm -rf "$PYDIR"
echo "PyPI smoke OK (dist/ kept)"

echo ""
echo "Artifact verification passed."
