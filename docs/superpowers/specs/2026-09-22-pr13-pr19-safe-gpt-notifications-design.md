# PR #13 and PR #19 Safe GPT Notifications Design

## Purpose

Replace PC-changing behavior in TeAka PRs #13 and #19 with read-only inspection and structured notification. The scripts must show Blair and GPT what they found and what they recommend without changing Git remotes, repository files, installed software, processes, services, scheduled tasks, ports, models, inbox commands, or existing outbox records.

## Authority and safety boundary

- Blair is the only approval authority for applying a proposed Git remote, file, service, process, task, port, package, model, inbox, or outbox repair.
- Running an audit or creating an append-only notification is not approval to apply the reported proposal.
- Historical instructions, existing configuration, inferred ownership, repository availability, and a script's `recommended_action` field do not constitute approval.
- Git remotes are always read-only in these PRs. The repaired scripts contain no remote mutation implementation.
- Existing inbox and outbox files are never overwritten, renamed, moved, truncated, or deleted.
- The only permitted filesystem mutation is creating one new notification file in an explicitly supplied, verified outbox directory.

## Verified bridge direction

Existing EV documentation identifies `EV_Bridge_Sync/outbox` and `bridge/outbox` as report/status paths from a device or runtime toward EV/GPT, while inbox locations contain commands toward the runtime. Therefore:

- Audit results go to an outbox, never to `gpt_inbox.json`.
- Inbox problems are detected and included as `PROPOSED_ONLY` repairs.
- These tools do not repair an inbox or outbox structure automatically.
- No specific PC path is assumed. The caller must provide the exact existing outbox directory.

## Common notification contract

Every audited script prints one complete UTF-8 JSON object to standard output. It may also create one timestamped JSON file when the caller explicitly supplies a GPT outbox path.

Required fields:

```json
{
  "schema": "ev.gpt.notification.v1",
  "notification_id": "uuid",
  "created_utc": "ISO-8601 timestamp",
  "source_pr": 13,
  "source_script": "script filename",
  "mode": "READ_ONLY_AUDIT",
  "approval_authority": "Blair",
  "approval_state": "NOT_APPROVED",
  "findings": [],
  "proposed_actions": [],
  "writes_performed": [],
  "notification": {
    "stdout": true,
    "outbox_requested": false,
    "outbox_created": false,
    "outbox_path": null,
    "error": null
  }
}
```

Each proposed action contains `status: "PROPOSED_ONLY"`, its evidence, exact target, risk, and the command or operation that would be required. It must not contain secrets.

## Outbox validation and append-only write

Notification file output is opt-in through an explicit `GptOutboxPath`/equivalent argument.

Before creating a notification, the script must verify:

1. The supplied path is absolute.
2. The directory already exists and is a directory.
3. Its final directory name is `outbox`, case-insensitively.
4. The destination filename is newly generated from UTC timestamp plus notification UUID.
5. The destination does not already exist.

The script opens the destination with create-new/exclusive semantics. It never creates parent directories and never falls back to another path. Validation or write failure is recorded in the stdout JSON and does not trigger any other mutation.

## PR #13 behavior

### `scripts/rebind_pc_git_owner.ps1`

- Enumerate only explicitly configured candidate repository paths.
- For each existing Git worktree, report resolved path, current branch, HEAD, dirty state, and every remote URL.
- Compare observed remotes with proposed owner mappings.
- Mark unknown, missing, GEMBot29, Starforge, or cross-repository substitutions as `UNVERIFIED`.
- Never call `git remote set-url`, `git remote add`, or another mutating Git command.
- Remove `ApplyRemotes` and any equivalent mutation path.

### `scripts/rebind_blairgem1234_files.py`

- Scan only explicitly supplied roots and allow-listed text extensions.
- Report exact file, line, observed reference, and proposed reference.
- Do not open files for writing, perform replacements, change encoding, or create backups.
- Remove `--apply` and all write implementations.
- Do not translate GEMBot29 or Starforge references into `BlairGem1234/Ev` without separate verified mapping evidence and Blair approval.

## PR #19 behavior

### `scripts/ev_amd_ollama_split.ps1`

- Inspect GPU, memory, Ollama processes, command lines, and listeners.
- Report whether the verified port 11434 owner conflicts with a service or scheduled task.
- Never call `Stop-Process`, `Start-Process`, start `ollama serve`, change environment persistently, or pull/load a model.

### `scripts/ev_operator_win_bootstrap.ps1`

- Report `curl.exe`, `uv`, PowerShell, and candidate installation status.
- Never install packages, change aliases, edit PATH, download installers, invoke remote scripts, or execute `winget`.
- Suggested installation commands appear only as `PROPOSED_ONLY` data.

### `scripts/ev_ollama_port_fight.ps1`

- Remain diagnostic.
- Remove instructions that recommend disabling the established `EV_Blair_Ollama_11434` task.
- Report conflicts and request Blair approval for any corrective action.

### `evbot/ev_ollama_brain_flask.py`

- Keep the default bind on loopback port 8081 and refuse port 8080.
- Make no directories and write no JSONL log files.
- Emit operational events to stdout using the common notification schema.
- Never stop, restart, install, disable, or reconfigure upstream services.

### Test and documentation scripts

- Health/test scripts may make bounded read-only HTTP requests and inspect listeners.
- They do not start services, post commands to EV Command, or repair failures.
- Documentation must label every change command as external, approval-gated guidance rather than something these scripts execute.

## Approval-gated future actions

These PRs deliberately contain no apply engine. If Blair later approves a specific change, it must be implemented as a separate narrowly scoped change with:

- exact target identity;
- before-state evidence;
- explicit Blair approval recorded outside the generated notification;
- backup or rollback method where applicable;
- one bounded mutation;
- post-change verification;
- no reuse of a general recursive rewrite engine.

## Tests and acceptance criteria

Automated tests must prove:

- default execution creates no files and changes no state;
- no production script contains or invokes prohibited mutation commands;
- stdout always contains valid `ev.gpt.notification.v1` JSON;
- an invalid or missing outbox produces no file;
- a valid explicit outbox creates exactly one new file;
- a pre-existing filename is never overwritten;
- inbox files are never changed;
- Git remotes before and after the PR #13 audit are identical;
- process, service, scheduled-task, port, package, model, and environment state before and after PR #19 audits are identical;
- port 8080 remains reserved for EV Command and Flask refuses to bind it;
- secrets and credentials are excluded from reports.

## Delivery sequence

1. Repair PR #13 independently and verify its branch.
2. Repair PR #19 independently and verify its branch.
3. Request independent code review of each repaired head.
4. Present exact commits, tests, remaining gaps, and merge recommendation to Blair.
5. Do not merge either PR without Blair's separate approval.
