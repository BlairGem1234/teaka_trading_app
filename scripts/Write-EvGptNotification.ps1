#Requires -Version 5.1

$Script:EvToolHubContext = [ordered]@{
    name = "Windows Quick Command Cheat Sheet - EV (Tool Hub)"
    drive_id = "1WBce_dHS5JI0n1JMI1GVb7A5fSKt1XLLy9-wzeWxvwQ"
    link_brain_drive_id = "1G4Ip0-XHCDnLG1FTqbnRFe2_qfvT6Fz39cp0acEKqcw"
    gpt_task = "Review this notification and report findings to Blair. Do not execute proposed actions without Blair approval."
}

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
        tool_hub = $Script:EvToolHubContext
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

function Add-EvFinding {
    param([hashtable]$Report, [hashtable]$Finding)
    $Report.findings = @($Report.findings) + $Finding
}

function Add-EvProposal {
    param([hashtable]$Report, [hashtable]$Proposal)
    $Proposal.status = "PROPOSED_ONLY"
    $Report.proposed_actions = @($Report.proposed_actions) + $Proposal
}

function Write-EvNotification {
    param([hashtable]$Report, [string]$GptOutboxPath)
    if ($GptOutboxPath) {
        $Report.notification.outbox_requested = $true
        $Report.notification.outbox_path = $GptOutboxPath
        try {
            $full = [System.IO.Path]::GetFullPath($GptOutboxPath)
            if (-not [System.IO.Path]::IsPathRooted($GptOutboxPath)) { throw "gpt outbox path must be absolute" }
            if (-not (Test-Path -LiteralPath $full -PathType Container)) { throw "gpt outbox path must be an existing directory" }
            if ([System.IO.Path]::GetFileName($full).ToLowerInvariant() -ne "outbox") { throw "gpt outbox directory name must be outbox" }
            $name = "{0}_{1}.json" -f ([DateTime]::UtcNow.ToString("yyyyMMddTHHmmssZ")), $Report.notification_id
            $destination = Join-Path $full $name
            $json = $Report | ConvertTo-Json -Depth 10
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($json + [Environment]::NewLine)
            $stream = [System.IO.File]::Open($destination, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
            try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
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
    $Report | ConvertTo-Json -Depth 10
}
