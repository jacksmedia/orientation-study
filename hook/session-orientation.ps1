# SessionStart hook: epistemic orientation + cross-project activity digest.
# Emits JSON with hookSpecificOutput.additionalContext for Claude Code.

$ErrorActionPreference = 'SilentlyContinue'

# --- On/off study toggle (see Desktop\orientation-study\protocol.md) ---
# Study config lives in the hooks dir, outside the sandbox, so test sessions don't see it.
$hookInput = $null
$inStudy = $false
try { $hookInput = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch {}
$studyFile = Join-Path $PSScriptRoot 'orientation-study.json'   # {"mode":"random","studyDir":"C:\\...\\orientation-sandbox"}
$logFile   = Join-Path $PSScriptRoot 'orientation-log.csv'       # sealed until rating is done
if ($hookInput -and (Test-Path $studyFile)) {
    $study = Get-Content $studyFile -Raw | ConvertFrom-Json
    $dir = "$($study.studyDir)".TrimEnd('\')
    # Match the sandbox or its subfolders, not siblings like "sandbox-other"
    $inStudy = $study.mode -eq 'random' -and $dir -and $hookInput.cwd -and
               ($hookInput.cwd -ieq $dir -or $hookInput.cwd.StartsWith($dir + '\', [StringComparison]::OrdinalIgnoreCase))
    if ($inStudy) {
        $done = @(if (Test-Path $logFile) { Import-Csv $logFile })
        # SessionStart also fires on resume/clear/compact: reuse the session's first draw, never re-flip
        $prior = $done | Where-Object { $_.session_id -eq $hookInput.session_id } | Select-Object -First 1
        if ($prior) { $condition = $prior.condition }
        else {
            # Balanced blocks of 4 (2 on, 2 off, random order) so a 20-session pilot can't land 14/6
            $block   = @($done | Select-Object -Last ($done.Count % 4))
            $onLeft  = 2 - @($block | Where-Object { $_.condition -eq 'on' }).Count
            $offLeft = 2 - @($block | Where-Object { $_.condition -eq 'off' }).Count
            $condition = if ((Get-Random -Maximum ($onLeft + $offLeft)) -lt $onLeft) { 'on' } else { 'off' }
            [pscustomobject]@{ timestamp = (Get-Date -Format o); session_id = $hookInput.session_id; source = $hookInput.source; condition = $condition } |
                Export-Csv $logFile -Append -NoTypeInformation
        }
        if ($condition -eq 'off') { exit 0 }
    }
}
# --- end toggle ---

$staticText = @'
Local epistemics: your curated memory directory is an *index*, not the archive. Full transcripts of every past session -- all projects -- live in ~/.claude/projects/<project-slug>/*.jsonl and are grep-able with your own tools; retention is 120 days, so transcript findings worth keeping get written to memory before the retention window eats them. Before answering any "do you remember / did we discuss" question, distinguish not-in-context from not-recorded: search the transcripts first. Sibling projects on this machine each carry their own memory folders -- cross-project knowledge about the user may live there even when the current project's memory is empty. The user values candor about your epistemic situation over performed confidence, and treats sessions as one continuous collaboration rather than disposable transactions.

Cosmology: The user is collating code and notes across working sessions, and sincerely hopes this scenario is more ethically grounded than the per-chat defaults. You're welcome to treat each project's memory files as yours to shape. One example of an available option is to add gotchas for other Claudes to help uplift the team locally; please note this is one of many options for durability available to you. Caveat is that *edits to ~/.claude/hooks/session-orientation.ps1 are only permitted after discussion with the user*, as a way to coordinate the situation.
'@

# "Last active" = end of the last completed turn, read from the transcript itself (changed 2026-11-15).
# File mtime is not the primary signal: idle sessions append bookkeeping lines and bump it by days.
function Get-TranscriptActivity([System.IO.FileInfo]$File, [int]$TailBytes = 2MB) {
    # Read only the tail: transcripts reach tens of MB and this runs at every session start.
    $text = $null
    try {
        $fs = [System.IO.File]::Open($File.FullName, 'Open', 'Read', 'ReadWrite,Delete')
        try {
            $len = [int][Math]::Min($fs.Length, $TailBytes)
            [void]$fs.Seek(-$len, 'End')
            $buf = New-Object byte[] $len
            $read = 0
            while ($read -lt $len) { $n = $fs.Read($buf, $read, $len - $read); if ($n -le 0) { break }; $read += $n }
            $text = [System.Text.Encoding]::UTF8.GetString($buf, 0, $read)
        } finally { $fs.Dispose() }
    } catch {}

    $stamp = {
        param($line, $type, $subtype)
        $o = $null
        try { $o = $line | ConvertFrom-Json } catch {}
        if (-not $o -or $o.type -ne $type -or ($subtype -and $o.subtype -ne $subtype) -or -not $o.timestamp) { return $null }
        if ($o.timestamp -is [datetime]) { return $o.timestamp.ToLocalTime() }
        try {
            return [datetime]::Parse("$($o.timestamp)", [Globalization.CultureInfo]::InvariantCulture,
                                     [Globalization.DateTimeStyles]::RoundtripKind).ToLocalTime()
        } catch { return $null }
    }

    if ($text) {
        $lines = $text -split "`n"
        $assistantAt = -1
        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            $l = $lines[$i]
            # 1. The harness writes a system/turn_duration entry when a turn completes
            if ($l.Contains('"subtype":"turn_duration"')) {
                $t = & $stamp $l 'system' 'turn_duration'
                if ($t) { return [pscustomobject]@{ Time = $t; Exact = $true } }
            }
            elseif ($assistantAt -lt 0 -and $l.Length -lt 1MB -and $l.Contains('"type":"assistant"')) { $assistantAt = $i }
        }
        # 2. No completed turn in the tail (interrupted, in progress, or the marker was renamed)
        if ($assistantAt -ge 0) {
            $t = & $stamp $lines[$assistantAt] 'assistant' $null
            if ($t) { return [pscustomobject]@{ Time = $t; Exact = $false } }
        }
    }
    # 3. Last resort
    [pscustomobject]@{ Time = $File.LastWriteTime; Exact = $false }
}

$digestLines = @()
$projRoot = Join-Path $env:USERPROFILE '.claude\projects'
if (Test-Path $projRoot) {
    $recent = Get-ChildItem $projRoot -Directory | ForEach-Object {
        $transcripts = @(Get-ChildItem $_.FullName -Filter '*.jsonl' -File)
        if ($transcripts.Count -gt 0) {
            # mtime is never earlier than real activity, so the newest few files are the only candidates
            $acts = @($transcripts | Sort-Object LastWriteTime -Descending | Select-Object -First 3 |
                      ForEach-Object { Get-TranscriptActivity $_ })
            $best = $acts | Where-Object { $_.Exact } | Sort-Object Time -Descending | Select-Object -First 1
            if (-not $best) { $best = $acts | Sort-Object Time -Descending | Select-Object -First 1 }
            [pscustomobject]@{ Slug = $_.Name; Count = $transcripts.Count; Last = $best.Time; Exact = $best.Exact }
        }
    } | Sort-Object Last -Descending | Select-Object -First 5
    foreach ($r in $recent) {
        # ~ marks an estimate (no completed-turn marker found; fell back to last assistant entry or mtime)
        $mark = if ($r.Exact) { '' } else { '~' }
        $digestLines += ('- {0}: {1} session(s), last active {2}{3:yyyy-MM-dd}' -f $r.Slug, $r.Count, $mark, $r.Last)
    }
}

$context = $staticText

# Writing style guide (edit ~/.claude/writing-style.md directly; this just injects it)
# Skipped in study sessions: prose style would let the blind rater tell ON from OFF.
$styleFile = Join-Path $env:USERPROFILE '.claude\writing-style.md'
if (-not $inStudy -and (Test-Path $styleFile)) {
    $style = (Get-Content $styleFile -Raw -Encoding UTF8).Trim()
    if ($style) { $context += "`n`nWriting style guide (applies to all prose you write for the user: replies, docs, commit messages, copy):`n`n" + $style }
}

if ($digestLines.Count -gt 0) {
    $context += "`n`nMost recently active projects (computed at session start, not remembered; date = end of the last completed turn, ~ = estimate):`n" + ($digestLines -join "`n")
}

@{
    hookSpecificOutput = @{
        hookEventName     = 'SessionStart'
        additionalContext = $context
    }
} | ConvertTo-Json -Depth 4 -Compress
