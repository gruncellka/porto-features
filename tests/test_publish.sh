#!/usr/bin/env bash
# Test npm and PyPI packages before publishing.
# Run from repo root: ./tests/test_publish.sh or make test-publish.
# Used in .github/workflows/publish.yml validate job to reject publish if this fails.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Use venv if present (local), else current python/pip (CI)
if [ -f venv/bin/activate ]; then
    . venv/bin/activate
fi

echo "=== Testing NPM package ==="
npm pack --silent
TARBALL="$(ls -t gruncellka-porto-features-*.tgz 2>/dev/null | head -1)"
test -n "$TARBALL" || { echo "No tarball produced"; exit 1; }
for forbidden in "docs/" "scripts/" ".cursor/" "catalog_baseline" "valid_GB.json" "valid_NO.json"; do
  if tar -tzf "$TARBALL" | grep -qF "$forbidden"; then
    echo "FAIL: npm package contains forbidden path: $forbidden"
    tar -tzf "$TARBALL" | grep -F "$forbidden" || true
    exit 1
  fi
done
if tar -tzf "$TARBALL" | grep -qE 'porto_features/features/[^/]+\.feature'; then
  echo "FAIL: npm package contains legacy flat features/*.feature paths"
  tar -tzf "$TARBALL" | grep -E 'porto_features/features/[^/]+\.feature' || true
  exit 1
fi
TESTDIR="${ROOT}/test-publish-npm"
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
const matrixDir = path.join(pdir, 'matrix');
const sdkFeatures = path.join(pdir, 'features/sdk');
const hasPy = (dir) => {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const e of entries) {
    if (e.name.endsWith('.py')) return true;
    if (e.isDirectory() && hasPy(path.join(dir, e.name))) return true;
  }
  return false;
};
if (hasPy(pdir)) { console.error('FAIL: .py file in npm package under porto_features/'); process.exit(1); }
if (!fs.existsSync(matrixDir)) { console.error('FAIL: matrix/ missing from npm package'); process.exit(1); }
if (!fs.existsSync(path.join(matrixDir, 'orders.generated.yaml'))) { console.error('FAIL: matrix/orders.generated.yaml missing'); process.exit(1); }
if (!fs.existsSync(sdkFeatures)) { console.error('FAIL: features/sdk/ missing from npm package'); process.exit(1); }
console.log('✓ require() OK, version:', pkg.version);
console.log('✓ matrix/ and features/sdk/ present');
console.log('✓ No Python files in porto_features/');
"
cat > smoke.ts <<'TS'
import { version } from '@gruncellka/porto-features';

const v: string = version;
console.log(v);
TS
npx tsc --ignoreConfig --noEmit --strict --target ES2020 --module commonjs smoke.ts
echo "✓ TypeScript import and types OK"
cd "$ROOT"
rm -rf "$TESTDIR" "$TARBALL"
echo "✓ NPM package test passed"

echo ""
echo "=== Testing PyPI wheel ==="
python3 -m pip install -q build 2>/dev/null || true
rm -rf build dist gruncellka_porto_features.egg-info dist-test
mkdir -p dist-test
python3 -m build --wheel --outdir dist-test 2>/dev/null
WHEEL_LIST="$(python3 -m zipfile -l dist-test/gruncellka_porto_features-*.whl)"
for forbidden in "docs/" "scripts/" ".cursor/" "gherlint.toml" "catalog_baseline" "valid_GB.json" "valid_NO.json"; do
  if echo "$WHEEL_LIST" | grep -qF "$forbidden"; then
    echo "FAIL: PyPI wheel contains forbidden path: $forbidden"
    echo "$WHEEL_LIST" | grep "$forbidden" || true
    exit 1
  fi
done
if echo "$WHEEL_LIST" | grep -qE 'porto_features/features/[^/]+\.feature'; then
  echo "FAIL: PyPI wheel contains legacy flat features/*.feature paths"
  echo "$WHEEL_LIST" | grep -E 'porto_features/features/[^/]+\.feature' || true
  exit 1
fi
python3 -m pip install -q --force-reinstall dist-test/gruncellka_porto_features-*.whl
PYDIR="${ROOT}/test-publish-pypi"
rm -rf "$PYDIR" && mkdir -p "$PYDIR"
cd "$PYDIR"
python3 -c "
from pathlib import Path
import porto_features
root = Path(porto_features.__file__).parent
features = root / 'features'
fixtures = root / 'fixtures'
matrix = root / 'matrix'
assert features.exists(), 'features/ missing'
assert fixtures.exists(), 'fixtures/ missing'
assert matrix.exists(), 'matrix/ missing'
assert list(features.rglob('*.feature')), 'no .feature files'
assert list(fixtures.rglob('*.json')), 'no .json in fixtures/'
assert (matrix / 'orders.generated.yaml').is_file(), 'orders.generated.yaml missing'
print('✓ porto_features import OK')
print('✓ features/, fixtures/, and matrix/ present')
"
cd "$ROOT"
rm -rf dist-test "$PYDIR"
echo "✓ PyPI package test passed"
echo ""
echo "All publish tests passed."
