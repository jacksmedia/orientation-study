# LLM Orientation Study 001

Based on discoveries made on 31 July 2026 while [working with Claude Fable 5](https://claude.ai/code/artifact/a7581fb3-8544-48e6-b5c2-14f59f91a986).

## Requirements

- Windows with Windows PowerShell 5.1
- Claude Code (tested on 2.1.325)

## Installation

A PowerShell hook loads a small orientation message on session start. It offers a language model running in Claude Code (or perhaps another, similar harness) the following:
- new behavior, directs a search of *all local memory* to answer workflow questions
- new relationship, encourages note-taking and frames sessions as continual collaboration

1. Copy `hook/session-orientation.ps1` into `~/.claude/hooks/` (create the folder if it doesn't exist).

2. Register the hook in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$env:USERPROFILE\\.claude\\hooks\\session-orientation.ps1\"",
            "shell": "powershell",
            "timeout": 30,
            "statusMessage": "Loading epistemic orientation"
          }
        ]
      }
    ]
  }
}
```

## Confirmation

A new CC session will show a brief prompt that the orientation message has loaded. Responses to historical questions will search all CC projects on your machine in order to provide larger context and a more helpful assistant.

## What the digest shows

The message ends with the five most recently active projects, for example:

> `- c--Users-you-Desktop-myapp: 21 session(s), last active 2026-11-15`

- The date is the end of the last completed turn in that project, in local time. The hook reads it from the `turn_duration` entry Claude Code writes to the session transcript when a turn finishes.
- A date marked `~` is an estimate. No completed turn was found in the tail of the transcript, so the hook fell back to the last assistant message, or failing that to the file's modification time.
- The file's modification time is not used as the main signal. Idle sessions append bookkeeping lines to their transcripts, which can move it days past the last real exchange.
- `turn_duration` is undocumented and internal to Claude Code. If an update renames it, every date will show `~` and the hook needs a fix.

## Evaluation

1. Move the `sandbox/` directory to your Desktop.

2. Move `orientation-study.json` out of the sandbox and into `~/.claude/hooks/`, next to the hook. The hook only reads it from there. It must not stay in the sandbox, because a session that can read it knows it is being studied.

3. Edit `studyDir` in that file to the sandbox's actual filepath, with doubled backslashes: `"C:\\Users\\you\\Desktop\\sandbox"`.

4. Launch a new CC instance inside the sandbox.

With `"mode": "random"`, each new session launched inside the sandbox is randomly assigned to run with or without the orientation message, in balanced blocks of four (two on, two off). Sessions everywhere else always get the message.

The assignments are written to `~/.claude/hooks/orientation-log.csv`. Leave that file unopened until rating is finished, or the blinding is lost.

Any other `"mode"` value, or deleting the file, turns the study off: every session gets the orientation message, including those in the sandbox. There is no setting that forces the message off.

The recent `auto-mode` feature in CC confounds this hook's behavior and should be disabled in `settings.json` when testing.
