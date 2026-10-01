#!/usr/bin/env bash
# Check-only: sample reth :8545 for any non-empty blocks. No start, no reset, no tx.
set -u
echo "CHECK ONLY — will not launch ev-node, will not reset .evm, will not submit txs"
echo "This reads reth JSON-RPC on 127.0.0.1:8545. Sequencer 26657 stays untouched."
echo

python3 - <<'PY'
import json, urllib.request
R = "http://127.0.0.1:8545"

def c(m, p):
    q = urllib.request.Request(
        R,
        data=json.dumps({"jsonrpc": "2.0", "method": m, "params": p, "id": 1}).encode(),
        headers={"Content-Type": "application/json"},
    )
    return json.loads(urllib.request.urlopen(q, timeout=8).read()).get("result")

head = int(c("eth_blockNumber", []), 16)
print("HEAD", head)
seen = set()
hits = []
hs = list(range(0, min(head, 32) + 1)) + list(range(max(0, head - 32), head + 1))
st = max(1, head // 128)
hs += list(range(0, head + 1, st))
for h in hs:
    if h in seen or h > head:
        continue
    seen.add(h)
    b = c("eth_getBlockByNumber", [hex(h), False])
    if not b:
        continue
    n = len(b.get("transactions") or [])
    g = int(b.get("gasUsed") or "0x0", 16)
    if n or g:
        hits.append("%s txs=%s gas=%s %s" % (int(b["number"], 16), n, g, b["hash"]))
        if len(hits) >= 20:
            break
print("SAMPLED", len(seen), "HITS", len(hits))
print(" | ".join(hits) if hits else "NO_TX_IN_SAMPLE")
PY

echo
echo "=== TXPOOL (optional) ==="
curl -sS --max-time 5 -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","method":"txpool_status","params":[],"id":1}' \
  http://127.0.0.1:8545 || echo TXPOOL_UNAVAILABLE
echo
echo "=== COMPLETE — READ ONLY ==="
echo "DOWN reth means do not start it from this script. Do not start ev-node."
