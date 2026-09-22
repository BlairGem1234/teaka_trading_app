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

`Cargo.toml:115 harness = false` is on `[[bench]] name = "benchmarks"` only, not the e2e tests. Grep found **no** `fn main` and **no** `26657` / `ev-node` / `std::process::exit` in those two files. They have 26 / 29 `#[test]` attrs and should use the default rustc harness. Silent cargo test is still unexplained. Next: `scripts/PASTE_WSL_CARGO_TEST_BINLIST.txt` runs `--list` on the built binary. Do not start ev-node.
