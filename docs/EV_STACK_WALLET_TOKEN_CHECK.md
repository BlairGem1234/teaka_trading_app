# EV stack — wallet / token check (this repo)

This TeAka recovery fork is **not** the full Windows EV tree. README and runtime JSON point at the local stack. There is still **no on-chain EV wallet** in git.

## What is in this repo (the EV stack pointers)

| Item | What it is | Wallet / tradable token? |
| --- | --- | --- |
| `bridge/ev_geoproof/geoproof_token.json` | GeoProof (`GPROOF`) hash-linked geospatial evidence spec | **No.** README: not a trading token. No contract address. |
| `ev_node.py` | Stub; real node is `evstack/ev-node` | No |
| `scripts/credential_vault.py` | Encrypts **exchange** API names into `bridge/vault/` (gitignored) | Not an ETH keystore. Vault dir is empty in git. |
| KuCoin env slots labeled from EV Stack | Exchange API access for TeAka trading | **Not** an on-chain wallet. Rotate anything that was ever committed. |
| `ev_virtual_brain.json` `token` field | String `STARFORGE_PHASE3_ACTIVATED` | Status flag, not a coin |

Related repos named in the GeoProof spec: `BlairGem1234/Ev`, `evstack/ev-node`. README still *names* old `E:\EV_Files` paths. PC check uses **C:** (user request 8 Oct 2026):

```text
C:\EV_Files\
C:\EV_Files\Bridge\
C:\EV_Brain\
C:\EV_AI\
D:\Starforge\Vault\
```

Do not recurse OneDrive/iCloud. Do not dump `KEYREGISTRY` or seeds. D: is map-first, no repair.

## Next PC check (names and public 0x only)

Git Bash paste: `scripts/PASTE_GITBASH_EV_STACK_PLACES.txt`. Send back directory names, `NO_KEYSTORE_NAME`, any `0x` lines, or `NO_ADDR`.
