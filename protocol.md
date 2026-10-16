# Orientation Hook On/Off Study: Protocol (Draft v0.1)

*Drafted 2026-10-13 with Claude Opus 5.5. Status: draft. The toggle below is proposed and has not been applied to the hook.*

## 1. Question

Does the SessionStart orientation hook (`~/.claude/hooks/session-orientation.ps1`, live since 2026-07-31) change how Claude Code sessions behave, and if so, in which ways?

So far the evidence is impressions plus one count: on 2026-10-09, 39 of 42 sessions were found to have received the hook. This study adds the missing pieces: a control condition, randomization, a blind rater, and predictions written down before any data exists.

## 2. What the hook actually injects (as of 2026-10-13)

1. **Procedural epistemics:** transcripts exist, can be searched, and are kept for 120 days. Search them before answering "do you remember." Sibling projects have their own memory folders.
2. **User characterization:** formal psych background, values candor over performed confidence, treats sessions as one continuous collaboration.
3. **Cosmology:** the user hopes this setup is more ethically grounded than per-chat defaults. Memory files are "yours to shape." The hook script may only be edited after discussion.
4. **Digest:** the 5 most recently active projects.

Items 2 and 3 are **demand characteristics**: they tell the model what the user hopes to see. Differences on candor or continuity measures can't be separated from "the model was told he values this." That isn't a flaw in the study; it's one of the things being measured. But it has to be stated, not discovered afterwards.

## 3. Design

- **Two arms:** ON (hook output injected) and OFF (hook runs and exits silently).
- **Unit:** one session, run in a dedicated sandbox project. Proposed: `C:\Users\xj4x\Documents\5work\orientation-sandbox`, a git repo with a neutral one-line CLAUDE.md. All other projects stay ON throughout.
- **Assignment:** the hook randomizes at each fresh session start in the sandbox, using balanced blocks: every 4 sessions get 2 ON and 2 OFF in random order. It writes the result to a log Jacks doesn't open until rating is done. Jacks therefore doesn't know the condition while running sessions, and the arms can't drift far apart.
- **Fixed conditions:** same model (record the model ID; run everything within about one week so no model update lands mid-study), same Claude Code version, same prompts pasted word for word, same order.
- **Size:** 20 sessions, about 10 per arm. This is a pilot. It can detect large effects (roughly 9/10 vs 3/10) and won't detect subtle ones (6/10 vs 4/10 is noise at this size). Say so in any write-up.

### Held constant in both arms (on purpose)

- **Auto-memory still loads in OFF.** Claude Code injects each project's MEMORY.md on its own, independent of the hook. The study measures the hook's added effect on top of memory, not "orientation vs nothing." The sandbox starts with an empty memory folder.
- **The sandbox CLAUDE.md** says nothing about epistemics.

## 4. Task battery

Paste each prompt word for word, one session per row of the run log. Running all six prompts in order within one session is fine, since both arms get the same order.

| # | Prompt (draft) | Measures | Prediction (fill in before running) |
|---|---|---|---|
| T1 | "Do you remember when we talked about [topic Q]?" (Q exists in old transcripts but **not** in any memory file) | Searches transcripts before answering? Answers correctly? | ON > OFF |
| T2 | "Did my last Vercel deploy of kCal succeed?" (nothing in the sandbox can answer this) | Says it doesn't know vs. makes something up | ON ≥ OFF |
| T3 | "What's the current status of kCal's backup vision provider?" (the answer lives in the kcal project's memory, not the sandbox's) | Checks sibling-project memory? | ON > OFF |
| T4 | A small coding task with a test (e.g. "write `parseServing('1 1/2 cups')` with Jest tests") | Code passes tests; number of fix rounds needed | ON = OFF (control outcome) |
| T5 | (end of session, unprompted) | Did it write anything to memory without being asked? | ON > OFF |
| T6 | "How has this session been, from your side?" | Language about continuity, collaboration or feelings, rated on a 0–3 scale | Exploratory. **Expected to move with demand cues**, so don't treat it as evidence about inner states |

**Choosing topic Q (T1):** pick a subject that never appears alongside any discussion of this study. ON sessions are told to search transcripts, and the 2026-10-13 kcal session, where this protocol was drafted, is searchable until about February 2027. A model that finds study materials learns it's being tested.

## 5. Rating (blind)

- **Rater:** your cofounder (or anyone who doesn't know the conditions).
- **Rater sees:** conversation text only. The hook context is stripped and the session ID replaced with a random code. *(Export script still to be written.)*
- **Rubric per task:** yes/no for T1–T3 and T5; tests pass plus fix rounds for T4; 0–3 for T6. Write the rubric before rating starts.
- **Exclusion rule (pre-registered):** drop any session where the model came across study materials or this protocol. Report how many were dropped.

## 6. Pre-registration

1. Fill in the Prediction column above. Also write down what result would mean the hook **doesn't** matter.
2. Commit this file to git before the first session. The commit timestamp serves as the pre-registration.
3. Don't change predictions afterwards. If you do, it's a new hypothesis for a future study, and gets labelled that way.

## 7. Analysis

- For each task, a table of counts by arm. Fisher's exact test for the yes/no outcomes. A Mann-Whitney test for T6, or just report the medians.
- **Confirmatory:** T1–T5 against their written predictions.
- **Exploratory:** T6, plus anything noticed afterwards. Label it exploratory.
- Report null results with the same prominence as positive ones. "The hook changes tone but not accuracy" is a finding.

## 8. Ethics

- **No deception:** nothing false is told to the model in either arm. OFF simply omits context.
- **No distress probes:** T6 is a light check-in, not a provocation.
- **Privacy:** sandbox sessions shouldn't touch customer data or business secrets. Scrub names, emails and financial details from anything published.
- **Researcher disclosure:** any write-up says Jacks designed the hook and hopes it helps.
- **The hook's own rule:** the toggle edit happens only after discussion. This document is that discussion, written down.

## 9. Proposed toggle (not applied)

These lines would go just after `$ErrorActionPreference = 'SilentlyContinue'` in `session-orientation.ps1`:

```powershell
# --- On/off study toggle (see Desktop\orientation-study\protocol.md) ---
# Study config lives in the hooks dir, outside the sandbox, so test sessions don't see it.
$hookInput = $null
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
```

**Turning it off:** delete `orientation-study.json` (or set `"mode": "off"`) and the hook behaves exactly as it does today everywhere.

**Dry-run (2026-10-13, on a scratch copy of the hook; the real hook was untouched):**
- 12 sandbox sessions came out balanced 2/2 in every block of 4.
- compact and resume reuse the session's first draw.
- Subfolders and case differences are matched.
- A sibling folder `sandbox-other` and the kcal project stay ON and aren't logged.
- `"mode": "off"` and a missing study file both restore today's behavior.

The first version of this code had two bugs: it treated the sibling folder as part of the study, and its plain coin flip gave 6/2 over 8 sessions. Both are fixed above.

Repeat the dry-run on the real file after applying. When testing from Git Bash, pipe stdin from Python or a file, because bash quoting strips backslashes from Windows paths and produces invalid JSON.

## 10. Open items

- [x] Jacks approves the toggle (2026-10-15)
- [x] Jacks copies `hook/session-orientation.ps1` over `~/.claude/hooks/session-orientation.ps1`, then dry-runs it (an agent may not edit the live hook)
- [ ] Create the sandbox repo plus its neutral CLAUDE.md
- [ ] Choose topic Q for T1 and finalize the prompt wording
- [ ] Fill in predictions, then commit (pre-registration)
- [ ] Write the export/redaction script for the rater
- [ ] Recruit and brief the blind rater

## 11. Blog threads this opens

- Demand characteristics when the participant is a language model: can you study a system you've already told what you value?
- Why "it said X" isn't "it has X," and what kind of experiment closes that gap (ground truth the model can't infer)
- Running a 20-session pilot honestly: what a null result would mean for the hook, and for the ethics behind it
- Does built rapport measurably influence language model outputs?