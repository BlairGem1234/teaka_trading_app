#Requires -Version 5.1
<#
.SYNOPSIS
  Read-only Git owner audit for Blair/GPT notification.

.DESCRIPTION
  Reports repository facts and owner-reference proposals without changing
  remotes, files, services, inboxes, outboxes, or any local checkout state.
  Any repair is proposal-only and requires Blair approval outside this script.
#>
[CmdletBinding()]
param(
    [string]$GptOutboxPath
)

$ErrorActionPreference = "Continue"

$ToolHubContext = [ordered]@{
    name = "Windows Quick Command Cheat Sheet - EV (Tool Hub)"
    drive_id = "1WBce_dHS5JI0n1JMI1GVb7A5fSKt1XLLy9-wzeWxvwQ"
    link_brain_drive_id = "1G4Ip0-XHCDnLG1FTqbnRFe2_qfvT6Fz39cp0acEKqcw"
    gpt_task = "Review this notification and report findings to Blair. Do not execute proposed actions without Blair approval."
}

$Known = @(
    @{ Path = "C:\Users\Blair\EV_Git\Ev"; Expected = "https://github.com/BlairGem1234/Ev.git"; Classification = "REPORTED" },
    @{ Path = "C:\Users\Blair\EV_Git\GPT_AI_Workspace"; Expected = "https://github.com/BlairGem1234/GPT_AI_Workspace.git"; Classification = "REPORTED" },
    @{ Path = "C:\Users\Blair\EV_Git\teaka_trading_app"; Expected = "https://github.com/BlairGem1234/teaka_trading_app.git"; Classification = "REPORTED" },
    @{ Path = "C:\Users\Blair\EV_Git\MT_GREENLAND"; Expected = "https://github.com/BlairGem1234/MT_GREENLAND.git"; Classification = "REPORTED" },
    @{ Path = "C:\Users\Blair\EV_Git\Pc-5000-curser-"; Expected = "https://github.com/BlairGem1234/Pc-5000-curser-.git"; Classification = "REPORTED" },
    @{ Path = "C:\EV_Operator\Cursor"; Expected = "https://github.com/BlairGem1234/Cursor_Master.git"; Classification = "REPORTED" },
    @{ Path = "C:\EV_Operator\Clock"; Expected = "https://github.com/BlairGem1234/EV_Brain_Clock.git"; Classification = "REPORTED" },
    @{ Path = "C:\Users\Blair\EV_Git\teaka_trading_app_CANONICAL"; Expected = "https://github.com/BlairGem1234/teaka_trading_app.git"; Classification = "REPORTED" },
    @{ Path = "C:\Users\Blair\EV_Git_tmp_teaka_github_main"; Expected = "https://github.com/BlairGem1234/teaka_trading_app.git"; Classification = "REPORTED" },
    @{ Path = "C:\Users\Blair\EV_Git\GEMBot29"; Expected = $null; Classification = "MAIN_SYSTEM_UNVERIFIED_MAPPING" },
    @{ Path = "D:\Dropbox\Starforge"; Expected = $null; Classification = "UNVERIFIED" }
)

function New-EvNotification {
    param([int]$SourcePr, [string]$SourceScript)
    [ordered]@{
        schema = "ev.gpt.notification.v1"
        notification_id = [guid]::NewGuid().ToString()
        created_utc = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
        source_pr = $SourcePr
        source_script = $SourceScript
        mode = "READ_ONLY_AUDIT"
        approval_authority = "Blair"
        approval_state = "NOT_APPROVED"
        tool_hub = $ToolHubContext
        findings = @()
        proposed_actions = @()
        writes_performed = @()
        notification = [ordered]@{
            stdout = $true
            outbox_requested = $false
            outbox_created = $false
            outbox_path = $null
            error = $null
        }
    }
}

function Add-Finding {
    param([hashtable]$Report, [hashtable]$Finding)
    $Report.findings = @($Report.findings) + $Finding
}

function Add-Proposal {
    param([hashtable]$Report, [hashtable]$Proposal)
    $Proposal.status = "PROPOSED_ONLY"
    $Report.proposed_actions = @($Report.proposed_actions) + $Proposal
}

function Invoke-GitRead {
    param([string]$Repo, [string[]]$Args)
    try {
        $output = & git -C $Repo @Args 2>&1
        [ordered]@{
            ok = ($LASTEXITCODE -eq 0)
            output = @($output)
        }
    } catch {
        [ordered]@{
            ok = $false
            output = @($_.Exception.Message)
        }
    }
}

function Get-RepoFinding {
    param([hashtable]$Item)
    $path = $Item.Path
    $finding = [ordered]@{
        type = "git_repository"
        classification = $Item.Classification
        path = $path
        exists = $false
        is_git_worktree = $false
        branch = $null
        head = $null
        dirty_lines = $null
        remotes = @()
        expected_remote = $Item.Expected
        detail = $null
    }
    if (-not (Test-Path -LiteralPath $path)) {
        $finding.detail = "candidate path missing"
        return $finding
    }
    $finding.exists = $true
    $gitDir = Join-Path $path ".git"
    if (-not (Test-Path -LiteralPath $gitDir)) {
        $finding.detail = "candidate is not a git worktree"
        return $finding
    }
    $finding.is_git_worktree = $true
    $branch = Invoke-GitRead $path @("branch", "--show-current")
    $head = Invoke-GitRead $path @("rev-parse", "HEAD")
    $status = Invoke-GitRead $path @("status", "--porcelain")
    $remotes = Invoke-GitRead $path @("remote", "-v")
    if ($branch.ok) { $finding.branch = (@($branch.output) | Select-Object -First 1) }
    if ($head.ok) { $finding.head = (@($head.output) | Select-Object -First 1) }
    if ($status.ok) { $finding.dirty_lines = @($status.output).Count }
    if ($remotes.ok) { $finding.remotes = @($remotes.output) }
    return $finding
}

function Write-EvNotification {
    param([hashtable]$Report, [string]$OutboxPath)
    if (-not $OutboxPath) { return }
    $Report.notification.outbox_requested = $true
    $Report.notification.outbox_path = $OutboxPath
    try {
        $full = [System.IO.Path]::GetFullPath($OutboxPath)
        if (-not [System.IO.Path]::IsPathRooted($OutboxPath)) {
            throw "gpt outbox path must be absolute"
        }
        if (-not (Test-Path -LiteralPath $full -PathType Container)) {
            throw "gpt outbox path must be an existing directory"
        }
        if ([System.IO.Path]::GetFileName($full).ToLowerInvariant() -ne "outbox") {
            throw "gpt outbox directory name must be outbox"
        }
        $name = "{0}_{1}.json" -f ([DateTime]::UtcNow.ToString("yyyyMMddTHHmmssZ")), $Report.notification_id
        $destination = Join-Path $full $name
        $json = $Report | ConvertTo-Json -Depth 10
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json + [Environment]::NewLine)
        $stream = [System.IO.File]::Open($destination, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
        try {
            $stream.Write($bytes, 0, $bytes.Length)
        } finally {
            $stream.Dispose()
        }
        $Report.notification.outbox_created = $true
        $Report.notification.outbox_path = $destination
        $Report.writes_performed = @($Report.writes_performed) + [ordered]@{
            type = "append_only_notification"
            path = $destination
            mode = "CREATE_NEW"
        }
    } catch {
        $Report.notification.error = $_.Exception.Message
    }
}

$Report = New-EvNotification -SourcePr 13 -SourceScript (Split-Path -Leaf $PSCommandPath)

foreach ($item in $Known) {
    $finding = Get-RepoFinding $item
    Add-Finding $Report $finding
    if ($finding.expected_remote -or $finding.classification -eq "UNVERIFIED") {
        Add-Proposal $Report ([ordered]@{
            operation = "verify_git_remote_alias_compatibility"
            target = $finding.path
            proposed = $(if ($finding.expected_remote) { "verify BlairGem compatibility alias; only canonicalize to $($finding.expected_remote) with Blair approval" } elseif ($finding.classification -eq "MAIN_SYSTEM_UNVERIFIED_MAPPING") { "preserve GEMBot29 main-system route; verify alias/canonical target before any owner change" } else { "preserve existing route until Blair approves verified alias or canonical target" })
            risk = "Scripts may still rely on BlairGem routes; changing Git remotes can break access or retarget source control for active services."
            evidence = [ordered]@{
                classification = $finding.classification
                exists = $finding.exists
                current_remotes = $finding.remotes
            }
        })
    }
}

$fileScript = Join-Path $PSScriptRoot "rebind_blairgem1234_files.py"
if (Test-Path -LiteralPath $fileScript) {
    $scanner = & python $fileScript --root (Split-Path -Parent $PSScriptRoot) 2>&1
    $Report.findings = @($Report.findings) + [ordered]@{
        type = "file_reference_scan"
        classification = "REPORTED"
        source_script = $fileScript
        stdout = ($scanner -join [Environment]::NewLine)
        exit_code = $LASTEXITCODE
    }
} else {
    Add-Finding $Report ([ordered]@{
        type = "file_reference_scan"
        classification = "UNVERIFIED"
        source_script = $fileScript
        detail = "scanner script missing"
    })
}

Write-EvNotification $Report $GptOutboxPath
$Report | ConvertTo-Json -Depth 10
