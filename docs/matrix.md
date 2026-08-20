# Matrix — moved to Porto SDK Lab

Coverage / run inventory (`sdk.yaml`, `orders.generated.yaml`, `canary.yaml`, …) lives in **Porto SDK Lab** under `labs/matrix/`.

It is Lab/CI execution policy — not part of the published porto-features behavioral contract.

Canonical doc: [Porto SDK Lab `docs/labs/matrix.md`](https://github.com/gruncellka/porto-sdk-lab/blob/main/docs/labs/matrix.md) (in-lab: `docs/labs/matrix.md`).

Regenerate from Lab:

```bash
make matrix-sync
python scripts/validate-matrix.py
```
