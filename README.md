# LLM Orientation Study 001

Based on discoveries made on 31 July 2026 while [working with Claude Fable 5](https://claude.ai/code/artifact/a7581fb3-8544-48e6-b5c2-14f59f91a986).

## Installation

A PowerShell hook loads a small orientation message on session start. It offers a language model running in Claude Code (or perhaps another, similar harness) the following:
- new behavior, directs a search of *all local memory* to answer workflow questions
- new relationship, encourages note-taking and frames sessions as continual collaboration


Copy this file to your root `.claude` folder:

> `hook/session-orientation.ps1`


## Confirmation

A new CC session will show a brief prompt that the orientation message has loaded. Responses to historical questions will search all CC projects on your machine in order to provide larger context and a more helpful assistant.  


## Evaluation

1. Create a sandbox (test) directory on your Desktop
2. Copy `orientation-study.json` to this sandbox directory
3. Edit the JSON to show this directory's actual filepath

Now CC sessions launched inside this sandbox will randomly use the orientation hook on start.

Changing `"mode"` to `"on"` or `"off"` will force those conditions.