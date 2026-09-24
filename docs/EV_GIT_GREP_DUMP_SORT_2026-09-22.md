# Ev git-grep dump sort — 2026-09-22

This is a **historical Ev git evidence archive**. It is not a live cargo log, not Evolve `26657`, not GEMBot MCP, and not a deployed token.

Do not recurse OneDrive, Dropbox, or `/EV_FullBackup` from chat. Map first. Do not repair D: from these files.

## 1. Scriptable iPhone repair (16 Jun 2026 checkpoint)

Source: `bridge/checkpoints/ev_scriptable_runtime_chat_checkpoint_2026-06-16.json`

| Fact | Read |
| --- | --- |
| Bulk repair | 443 files fixed, 0 errors, with backups |
| Remaining header hits | 526 — many duplicates / historical false positives |
| Path/injection hits | 446 — split **active scripts** vs reports/backups |
| Gate | Do not delete or overwrite without plan, backup, and approval |
| Box bridge | `EV_Box_Bridge_Drive_Copy.js` writes inbox/outbox/state/logs |

## 2. PC5000 mapping, not repair

Sources: `pc5000_split_index.json`, `pc5000_chat_handoff_20260616.json`, `pc5000_d_drive_collision_fault_map.json`

- Status was `mapping_not_repair`.
- Google Drive was colliding with **D:** while logs also mentioned **G:**.
- Dropbox is a separate mount (EV_Brain, EV_Bridge, GIS archives).
- Handoff rule: do not repair D: until hidden WD partitions, Google Drive alias, and Desktop registry path are captured.
- No repair of D:, Desktop redirection, scheduled tasks, services, or Defender was recorded in that checkpoint.
- `EV_Global_Ollama_Task_Repair.ps1` was **not** in the indexed GitHub tree.

## 3. MDM / C-drive evidence (April 2026 snapshot)

Sources: `docs/PC_MDM_MACHINE_STATE_REVIEW_2026-07-13.md`, `docs/PC_SYSTEM_STORAGE_MAP_2026-07-13.md`

- Machine identity in the ZIP: **BLAIRSPC**, HP laptop; historical Autopilot hashes differ between CAB and ZIP.
- Strong historical machine-state record. Not proof of current Intune/MDM enrollment.
- `EV_Global_Auth.log` is audit text with blank registry fields — not live Defender proof.
- Raw serials, hashes, SIDs, registry dumps were deliberately **not** committed.
- C-drive pressure was from EV/tool sprawl plus diagnostic copies, not from this Git record.

## 4. GeoNode blockchain overlays are data models

Sources: `GeoNode/overlays/Blockchain_overlay_conversion.json`, `Brittana_crypto_overlay.json`, `PROJECT_SEPARATION.md`

| Bucket | Meaning |
| --- | --- |
| Confirmed | CR3309 Wellington permit/resource/drillhole/assay/map fields can be JSON blocks |
| Inferred | Token-unit design; “chain” as a data architecture |
| **Not confirmed** | Deployed contract, live token, wallet, on-chain tx, compliant security token |

Project namespaces stay separate:

- `MACKLEY_EP52604` — Mackley River overlay (`Block_chain.json`, JSON-comment repair)
- `BRITANNIA_PP60713` — Britannia geology-to-chain overlay
- `MT_GREENLAND` — own Dropbox index; **Greenland Group is host rock, not Mt Greenland**
- `CRYPTO_SUPPORT_ONLY` — package/address index, not a geological project

## 5. Mt Greenland Dropbox index (backup mirrors)

Primary evidence lives under `/EV_FullBackup/...`. Duplicate `(1)` trees are fallbacks only.

Do not merge with Britannia because of West Coast / Greenland Group wording.

## 6. E: FuzzyBrain / EchoVault paths

`brain/EV_FuzzyBrain_State.json` points at `E:/EchoVault/...` and `E:/EV_Files/Logs/...`. Those are **path claims in Git**, not a live mount in this cloud agent.

Canonical architecture recorded in `Git_recovery` / access manifest: `C:\EV_Brain` primary runtime, Dropbox as sync/backup/bridge, phone as trigger node. Conflicting `E:\EV_Brain` log lines are historical, not a reason to rewrite drives.

## 7. Wellington GEO-020 token candidate (inferred only)

Source: `GeoNode/overlays/Blockchain_overlay_conversion.json` (CR3309 Wellington)

The overlay names possible units (permit-backed, tonnage-backed, drillhole, coal-quality, risk-adjusted). The same object lists what is required before any real token claim: current permit/legal status, ownership, JORC/NZ validation, updated resource model, contract address if deployed, wallet proof, investor disclosure.

`hash_plan` is SHA256 of canonical JSON blocks (GEO-010 → GEO-011 → GEO-012). That is a **data-link scheme**, not a chain tip.

Britannia (`Brittana_crypto_overlay.json`, `BRITANNIA_PP60713`) is the stronger geology-to-chain *source document*. `CRYPTO_SUPPORT_ONLY` is not a geological project. `Start_prompt_Crypto_geo.json` says stack small confirmed JSON blocks; do not solve the whole model in one pass.

## 8. PC5000 Git bridge agent — snapshots, not repair

Source: `tools/pc5000/Start-PC5000-GitBridgeAgent.ps1`

Approved actions in that script: `ping`, `cpp_integration_scan`, `gembot_process_snapshot`, `startup_sources_snapshot`, `d_drive_state`, `port_snapshot`, `codex_state_snapshot`.

The cycle **git pull / add inbox+outbox+bridge_agent / commit / push**. That is a mailbox loop, not a D: repair.

`bridge/commands/pc5000/gembot_repair_command.json` is a **template**. `local_confirmation_required_for_repair: true`.

June 2026 process maps list `C:\EV_Recovery\Launchers\` (`EV_AutoLaunch.cmd`, `EV_MasterMonitor.cmd`, `GemBot_Scheduler.cmd`, `GEMBot_Starforge.cmd`). Those are **historical execute paths**, not proof those processes are live today. Duplicate `pc5000_gembot_live_process_map.json` vs `_20260624_205406.json` is the same snapshot copied.

Do **not** commit Codex runtime: `config.toml`, `installation_id`, `.codex-global-state.json`, `goals_*.sqlite`, `logs_*.sqlite`, `memories_*.sqlite`, `state_*.sqlite`. The grep header that starts with those names is an **exclude pattern**, not a file to open.

## 9. Geo minerals “next proof” is still missing

Source: `docs/EV_GEO_MINERALS_BLOCKCHAIN_MAP_20260625.md`

Drive found `Existence_Check.log` with mineral/GIS and EV/Starforge **paths**. Next proof would be a manifest/sqlite/log linking `GIS.zip` or `Minerals_Permit_Applications.*` to `sha256` / `tx_hash` / `block_hash` / Starforge / `EV_GitExport`.

That link is **not** in this dump. Adjacent public tech (geoportals, metadata) is not an EV-owned ledger.

`docs/EV_BLOCKCHAIN_TRADING_INTEGRATION_MAP_20260624.md` already says: do not run live trading, submit blockchain transactions, import private keys, or start unknown nodes without explicit dry-run/testnet/local-only confirmation.

## 10. Teaka vs Ev vs Dropbox copy tree

Source: `docs/TEAKA_PUBLIC_GIT_RELATION_MAP_20260624.md`, `docs/EV_RUNTIME_MAP.md`

- This GitHub tree is the **BlairGem / BlairGem1234 Teaka recovery fork**, not the full E: app.
- Dropbox copies live under `/EV_FullBackup/copy teaka_tradeing_app/...` (misspelled) and the `(1)` duplicate.
- GPT Library (`docs/EV_GPT_LIBRARY_INDEX.md`) is **read/search only**.
- Drive/Dropbox/OneDrive are resolver/mirrors. Recursing them from chat hangs.

## 11. Grep tail is exhausted (stop pasting)

The last hits are the **same line** surviving many commits:

- `spinebank/SpineBank.md:28` — “return top 5 recent memory entries…” repeated across SHAs `fb59ff5` … `a7b9898`
- `bridge/protocol.md:9` — `- bridge/logs` twice
- `pythonista/ev_phone_github_bridge_watcher.py:223` — `return log`

That is `git grep` matching the word `log`, not new runtime evidence.

## 12. What this dump is not

- Not Nanle `cargo check` output
- Not Evolve ev-node / cometbft `:26657`
- Not GEMBot29 / `ev_gembot` MCP
- Not a go-live for trade or token issuance
- Not approval to recurse OneDrive or repair D:
- Not approval to git-push the PC5000 bridge agent from this chat

## Paste-safe WSL cargo (Nanle crate only)

Use the four lines in `scripts/PASTE_WSL_CARGO_CHECK.txt`. Do not paste markdown, comments, or chat sentences into Ubuntu.

## 13. Verified on Blairspc — 22 Sep 2026

Host: `blair@Blairspc` in `/mnt/c/Users/Blair/EV_Git/_Upstream/StarForge/Blockchain/Nanle-code-StarForge`

First paste mixed in chat prose (`This is still **Nanle StarForge**…`) and bash died with `syntax error near unexpected token '('` / `'one'`.

Clean four-line paste then produced:

```text
Checking starforge v0.1.0 (/mnt/c/Users/Blair/EV_Git/_Upstream/StarForge/Blockchain/Nanle-code-StarForge)
Finished `dev` profile [unoptimized + debuginfo] target(s) in 1m 47s
```

`CARGO_TARGET_DIR=/tmp/starforge-target` avoided NTFS `os error 5`. This is **check-only** of Nanle StarForge `v0.1.0`. It is not EV GEMBot, not a live token, and not `cargo build --release`. Ollama stays Windows **11434** / Docker **11435**. Do not run another cargo command unless asked.

## 14. EV node check-only (no start)

`scripts/PASTE_WSL_EV_NODE_CHECK.txt` and `scripts/ev_node_check_only.sh` / `.ps1` GET `127.0.0.1:26657/status`. They do not launch ev-node. `DOWN` means the node is not live — leave it down.

## 15. Nanle `cargo test` compile on Blairspc — 22 Sep 2026

Same crate, `CARGO_TARGET_DIR=/tmp/starforge-target`. Test profile **compiled**:

```text
Finished `test` profile [unoptimized + debuginfo] target(s) in 8m 19s
Running tests/deployment_preparation_e2e.rs
Finished `test` profile [unoptimized + debuginfo] target(s) in 1m 03s
Running tests/deployment_error_handling.rs
```

Paste did **not** include `test result: ok` or `FAILED`. `Refresh index: 100% (636/636)` is git index refresh, not a cargo verdict. Do not treat this as tests passed. Still Nanle StarForge, not EV GEMBot, not ev-node.

Re-run those two bins with `scripts/PASTE_WSL_CARGO_TEST.txt`. Paste the lines that say `test result:`.

Blairspc re-run Finished in 2.00s, started both bins, then returned to the shell with **no** `running N tests` and **no** `test result:`. `--list` also printed no test names.

`Cargo.toml:115 harness = false` is on `[[bench]] name = "benchmarks"` only. Direct binary `--list` printed **29 tests, 0 benchmarks, EXIT:0** for `deployment_error_handling`. `cargo test --test A --test B` was dropping harness output. Next: `scripts/PASTE_WSL_CARGO_TEST_RUN.txt` runs both bins with `--nocapture`. Do not start ev-node.

## 16. Nanle crypto git sort (check-only)

Expected origin: `https://github.com/Nanle-code/StarForge.git`. Do not invent a StarForge GitHub repo. Do not rebind GEMBot29. Do not start ev-node.

- Git Bash paste: `scripts/PASTE_GITBASH_NANLE_GIT_SORT.txt` (`/c/Users/Blair/...`)
- WSL paste: `scripts/PASTE_WSL_NANLE_GIT_SORT.txt` (`/mnt/c/Users/Blair/...`)
- Script: `scripts/nanle_git_sort_check_only.sh`

Blairspc Git Bash 22 Sep: `master` is **ahead 1** of `origin/master`.

- HEAD `9dfca15` `fix: restore StarForge compile and deployment tests`
- `origin/master` `f2298dc` Merge pull request #718 from kali-el/feat/ai_documentation
- origin `https://github.com/Nanle-code/StarForge.git`

The compile fixes are already a local commit on `master`. Do **not** `git push origin master` unless opening an upstream PR to Nanle-code. Do not invent a BlairGem StarForge repo.

Do **not** paste `PASTE_*_NANLE_GIT_COMMIT_LOCAL.txt` again. That was the pre-commit helper. Confirm the unpushed commit only with:

- Git Bash: `scripts/PASTE_GITBASH_NANLE_GIT_NOPUSH.txt`
- WSL: `scripts/PASTE_WSL_NANLE_GIT_NOPUSH.txt`

Expected: `## master...origin/master [ahead 1]` and `9dfca15` on the `origin/master..HEAD` line.

Blairspc glued this chat into Git Bash twice. `??: command not found`, `syntax error near unexpected token '('`, `$:` / `bash::` / `.txt: command not found`, `d354ef8: command not found`, `291c076: command not found`, and `scripts/test_nanle_git_sort_check_only.sh: No such file or directory` are **not** git failures. `??` lines are GEMBot29 untracked files. The `&` in `tpsonedrive.live.comqt=allmyphotos&.txt` started jobs 1597 and 1846; both already `Exit 127`. SHA lines were typed as commands, not `git checkout`. Same dumps still printed origin `https://github.com/Nanle-code/StarForge.git`, `## master...origin/master [ahead 1]`, HEAD `9dfca15`. The prompt is a clean Nanle `(master)` shell. Git is sorted. Give no further paste. Do not push.

## 17. GEMBot29 Git Bash (Blairspc) — inspect only, already pasted

Path: `C:\Users\Blair\EV_Git\GEMBot29` branch `main` HEAD `d3944c2` Initial EV AI repository.

- `origin` and `legacy-origin` are both `https://github.com/blairgem/GEMBot29.git`. Do not set-url unless asked to rebind.
- Tracked tree includes Python `Lib/` stdlib. That is git noise, not GEMBot app source.
- `ollama_bridge_flask.py` is **untracked**. Leave it untracked.
- Do **not** `git add` `Lib/site-packages`, `Scripts/activate`, `pyvenv.cfg`, `set_dropbox_token_log.txt`, or `*.bak_*`.
- `scripts/test_nanle_git_sort_check_only.sh` lives in the Teaka repo on this cloud agent, not GEMBot29. `No such file or directory` in GEMBot29 Git Bash is expected. Do not run Teaka `scripts/test_*.sh` there.

Inspect paste: `scripts/PASTE_GITBASH_GEMBOT29_GIT_SORT.txt`. Hide venv noise: `scripts/PASTE_GITBASH_GEMBOT29_LEAVE_UNTRACKED.txt`. Crypto crate git is Nanle at `/c/Users/Blair/EV_Git/_Upstream/StarForge/Blockchain/Nanle-code-StarForge`, not GEMBot29.

## 18. Evolve test node dump (Blairspc) — no trades in this paste

Inventory + logs from 22 Sep 2026. This is **evolve-test**, not a live token, not Nanle git, not GEMBot29.

| Fact | Read |
| --- | --- |
| chain_id | `evolve-test` |
| reth chainId | `0x4d2` = 1234 |
| sequencer height | 91317 |
| EL / reth blockNumber | `0x164b6` = 91318 |
| peers | 0 |
| DA cache | da_height=13, data_entries=0, header_entries=0; latest_da_height=205 |
| fee recipient | all-zero |
| crashing payloads | `"transactions":[]` |
| home | `.evm/config/evnode.yaml`, `genesis.json`, Badger SST/vlog under `.evm/data/evm-single/` |

Crash loop (6:13, 6:16–6:17, 9:04): EL is one block ahead; forkchoice rolls back to hash `0x48ee6968…` at 91317; sequencer rebuilds 91318 with a new timestamp; engine returns `status=VALID` and **nil PayloadID**; node treats that as critical and stops. Timestamp split: stored ExecMeta `1787696107` (2026-08-25T22:15:07Z) vs requested `1790111054` (2026-09-22T21:04:14Z). Reth engine log clip starts `2026-08-09T05:53:18Z`.

**Trades:** this paste has no swap, fill, order, transfer, or wallet activity. Every failed 91318 payload is empty txs. DA data_entries=0. Earlier Ev git-grep also did not confirm a deployed contract, live token, wallet, or on-chain tx. 91317 local blocks exist; their contents are not in this dump. Do not start ev-node to go looking. Leave it down. Do not wipe `.evm`.

Blairspc then ran a read-only `eth_getBlockByNumber` on reth `:8545` (script said READ ONLY / NO RESET / NO INIT). Confirmed:

| Block | Hash | Parent | UTC | gasUsed | tx_count |
| --- | --- | --- | --- | --- | --- |
| 91317 | `0x48ee6968…c7db5757` | `0x1b6f29b8…c97e546` | 2026-08-25T22:15:07Z | 0 | **0** |
| 91318 | `0x59e3e9f6…eaae550a` | `0x48ee6968…` | 2026-08-25T22:15:07Z | 0 | **0** |

Head is 91318. Both tip blocks are empty. LocalDA is `running` at `172.16.0.3:7980` with **empty block production** (`blockTime=1000`). Ports: 7980/8545/8546/8551/9001/30303 listening; 7331 and 7676 stopped; sequencer `:26657` not listed. LocalDA RPC `Invalid request` at 2026-08-26 and 2026-09-22T21:09:16Z is a bad JSON-RPC call, not a trade. Do not start the sequencer. Do not reset.

To check older blocks without starting the sequencer: WSL paste `scripts/PASTE_WSL_EV_TRADE_CHECK.txt` (reth `:8545` only). Send back `HEAD`, `SAMPLED`, `HITS` or `NO_TX_IN_SAMPLE`. Do not paste chat.

## 19. “Hidden” EV crypto / tokens — not in these logs

The 6:17PM / 9:04PM sequencer dump is the **same crash**, not a hidden wallet.

Every `payloadAttributes` has `"transactions":[]` and `suggestedFeeRecipient` all-zero. `nil PayloadID` means reth already has block 91318 (`0x59e3e9f6…`) and will not rebuild it with a new timestamp. That is an empty-block timestamp split on `evolve-test`, chain 1234. It is not a concealed token transfer.

Names that look like crypto but are not coins:

| Name | What it actually is |
| --- | --- |
| `.evm/data/evm-single/KEYREGISTRY` | BadgerDB internal file. Do not dump it. |
| GeoNode “token” units / GEO-020 | Overlay JSON design. Not a deployed contract. |
| `set_dropbox_token_log.txt` | Dropbox API log. Not a coin. |
| LocalDA empty block production | DA heartbeats on `:7980`, not user txs. |
| TeAka `paper_trading` | Virtual BTC-USDT fills. `live_trading_enabled: false`. |

To scan the local reth for ERC20 `Transfer` logs without starting the sequencer: `scripts/PASTE_WSL_EV_HIDDEN_TOKEN_CHECK.txt`. Send back `GENESIS_TX`, `TRANSFER_LOGS` or `NO_TRANSFER_LOGS`. Do not cat genesis secrets. Do not start ev-node.

Blairspc config/data dump adds:

- Raft is empty: `node_id`, `raft_addr`, and `peers` blank; `bootstrap: false`; dir `/root/.evnode/raft`. Solo test node, not a cluster hiding bags.
- `pruning_mode: disabled` — stored blocks are not being pruned away.
- SST/vlog/MANIFEST under `data/evm-single/` are Badger files, not wallets.
- Executor log `10:14–10:15PM`: heights **91273 through 91317** all `produced block ... txs=0`.
- First halt at 91318 was `invalid block time` — got `2026-08-25 22:15:07.402Z`, last `22:15:07.726Z` (timestamp went backwards ~324ms). Later restarts are the nil PayloadID loop. ev-reth `2026-08-09` warned beacon online but no consensus updates.

Still no trades. Do not start the sequencer. Do not dump `KEYREGISTRY`.

A token that was actually worth money would **not** need to live in git as a wallet file. Custody can be an exchange account, a seed offline, a contract admin key, or a legal claim. Missing a git wallet does **not** prove hidden value.

What *would* be required for value, and is still missing here:

- A ledger other people use (mainnet contract, listed ticker, exchange balance) — this node is `evolve-test`, chain 1234, **0 peers**
- At least one real transfer or mint — tip and 91273–91317 are `txs=0`
- A buyer or listing — GeoNode “token units” are overlay JSON with no contract address, wallet proof, or on-chain tx
- Control of that claim — we have not seen a funded exchange account or seed, and we will not hunt keys

Local empty blocks on a solo test node are not an asset. Do not import seeds or start unknown nodes to “find” them.

## 20. Search result — no EV wallet, no EV token in this evidence

TeAka git (`BlairGem1234/teaka_trading_app`) on 24 Sep 2026:

| Asked for | Found |
| --- | --- |
| Wallet file / keystore / seed | **None.** `SECURITY.md` forbids committing them. `Config/ev_keys.json` is paper mode only (`live_trading_enabled: false`), KuCoin env *names* for a future live mode, no keys. |
| Ethereum address in git | **None** except the all-zero fee recipient already in node logs. |
| EV token contract / ticker | **None.** No ERC20 address, no listed EV coin. GeoNode “token units” are overlay JSON. |
| Local node coinbase | Crash logs use `suggestedFeeRecipient` `0x000…000`. That is the zero address, not a funded wallet. |
| Local chain | `evolve-test` / reth `1234`, 0 peers, empty txs. Not a market. |

Do not dump `.evm/data/evm-single/KEYREGISTRY`, genesis secrets, or OneDrive seeds. Read-only RPC (reth already up): `scripts/PASTE_WSL_EV_WALLET_CHECK.txt` (`eth_accounts`, `eth_coinbase`, `eth_chainId`). Send back those JSON lines. Do not start ev-node.

Blairspc Git Bash 24 Sep ran that paste:

- `eth_accounts` → `[]` (no unlocked wallet)
- `eth_coinbase` → `unimplemented`
- `eth_chainId` → `0x4d2` (1234, `evolve-test`)
- `DONE_READ_ONLY`

## 21. Dropbox Starforge commit test is not the EV wallet

Path: `/d/iCloud/iCloudDrive/Dropbox 3/Starforge` commit `54d317108a8afd9fc023c6841560e6bfaafe2e17`. Safe blob/python/json read of **19** committed files, 0 failures. Tree is `Python_Env` stdlib, `Vault` chat/clock JSON, README, a ps1. `__hello__.py` / `beer.py` are CPython demos, not tokens. This is **not** Nanle-code/StarForge (no `Cargo.toml`). Not a wallet. Do not recurse iCloud/Dropbox. D: stays map-first, no repair. Git was not changed.
