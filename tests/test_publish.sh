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
const hasPy = (dir) => {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const e of entries) {
    if (e.name.endsWith('.py')) return true;
    if (e.isDirectory() && hasPy(path.join(dir, e.name))) return true;
  }
  return false;
};
if (hasPy(pdir)) { console.error('FAIL: .py file in npm package under porto_features/'); process.exit(1); }
console.log('✓ require() OK, version:', pkg.version);
console.log('✓ No Python files in porto_features/');
"
cat > smoke.ts <<'TS'
import { version } from '@gruncellka/porto-features';

const v: string = version;
console.log(v);
TS
npx tsc --noEmit --strict --target ES2020 --module commonjs --moduleResolution node smoke.ts
echo "✓ TypeScript import and types OK"
cd "$ROOT"
rm -rf "$TESTDIR" "$TARBALL"
echo "✓ NPM package test passed"

echo ""
echo "=== Testing PyPI wheel ==="
python3 -m pip install -q build 2>/dev/null || true
rm -rf dist-test && mkdir -p dist-test
python3 -m build --wheel --outdir dist-test 2>/dev/null
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
assert features.exists(), 'features/ missing'
assert fixtures.exists(), 'fixtures/ missing'
assert list(features.glob('*.feature')), 'no .feature files'
assert list(fixtures.rglob('*.json')), 'no .json in fixtures/'
print('✓ porto_features import OK')
print('✓ features/ and fixtures/ present with .feature and .json')
"
cd "$ROOT"
rm -rf dist-test "$PYDIR"
echo "✓ PyPI package test passed"
echo ""
echo "All publish tests passed."
