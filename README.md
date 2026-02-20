# claude-code-podeweb-agent

A specialized [Claude Code](https://code.claude.com/) subagent for **PowerShell 5.1/7+** and **[Pode.Web 0.8.3](https://badgerati.github.io/Pode.Web/)** development.

Generates correct Pode.Web code on the first attempt by embedding component reference, known bugs, workarounds, and production-validated patterns directly in the agent prompt.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Why this agent?

Pode.Web 0.8.3 has several **undocumented pitfalls** that cause frustrating errors:

| Problem | What happens | Agent knows the fix |
|---------|-------------|-------------------|
| Modal `-Title` parameter | 400 Bad Request | Use `-DisplayName` instead |
| Select `-Options` + `-ScriptBlock` | Parameter set conflict | Use `Register-PodeWebEvent` for onChange |
| `Update-PodeWebSelect` without `-Options` | PowerShell hangs waiting for input | Always pass `-Options` on Update |
| Checkbox `-Checked $true` | Positional parameter error | Use colon syntax `-Checked:$true` |
| Container `-Hide` + jQuery `.show()` | CSS `!important` blocks toggle | Use custom CSS without `!important` |
| Button inside Table ScriptBlock | Endpoint not registered | Place buttons outside the table |
| `-Content @()` empty array | 400 Bad Request | Remove the component if empty |

The agent also knows **5 PowerShell 5.1 gotchas** that are hard to debug:

- `$_` contamination inside `switch` blocks
- String interpolation bug in `.psm1` modules
- `Out-String -NoNewline` not available
- Colon syntax required for switch parameters
- `-Hide` CSS `!important` conflict

## Features

- **11-point pre-output checklist** - Every generated code is mentally verified against known issues
- **9 component quick reference** - Modal, Select, Checkbox, Button, Table, Textbox, Container, Events, Toast
- **3 ready-to-use page patterns** - Full page with KPI/table/modal, cascading select, responsive grid
- **PS 5.1 compatibility first** - No `??`, `??=`, `?.`, ternary, or other PS 7+ syntax by default
- **Auto web-fetch** - When unsure about a parameter, the agent checks the official Pode.Web docs

## Installation

### User-level (all projects)

Copy the agent file to your Claude Code agents directory:

```bash
# Clone the repo
git clone https://github.com/michelesant82-beep/claude-code-podeweb-agent.git

# Copy the agent definition
cp claude-code-podeweb-agent/agents/powershell-podeweb.md ~/.claude/agents/
```

### Project-level (single project)

```bash
cp claude-code-podeweb-agent/agents/powershell-podeweb.md .claude/agents/
```

### Manual

Download [`agents/powershell-podeweb.md`](agents/powershell-podeweb.md) and place it in `~/.claude/agents/` (user-level) or `.claude/agents/` (project-level).

## Usage

Once installed, Claude Code automatically delegates Pode.Web tasks to this agent. You can also invoke it explicitly:

```
Use the powershell-podeweb agent to create a dashboard page with KPI tiles, a filterable table, and a modal form
```

### Example prompts

| Prompt | What the agent does |
|--------|-------------------|
| "Create a server management page with add/edit/delete" | Generates full page with table, modal forms, badges, and toast notifications |
| "Debug: parameter set conflict on New-PodeWebSelect" | Identifies the `-Options`/`-ScriptBlock` conflict and provides the correct pattern |
| "Add a cascading select: department -> employee" | Generates parent select with `Register-PodeWebEvent` and child `Update-PodeWebSelect` |
| "Fix `$_` returning wrong value inside switch" | Recognizes the PS 5.1 `$_` contamination bug and suggests `foreach` loop |

## Agent configuration

| Setting | Value |
|---------|-------|
| Model | `sonnet` |
| Memory | `user` (persistent across sessions) |
| Tools | Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch |

The agent uses **Sonnet** for the best balance of speed and accuracy. It has persistent memory to learn new patterns and gotchas over time.

## Repository structure

```
claude-code-podeweb-agent/
├── README.md
├── LICENSE
├── CONTRIBUTING.md
├── agents/
│   └── powershell-podeweb.md    # Agent definition (install this file)
├── docs/
│   └── pode-web-bestpractice.md # Full Pode.Web 0.8.3 reference
└── examples/
    ├── 01-server-page.ps1       # Complete page: KPI + table + modal form
    ├── 02-debug-parameterset.md # Debug guide: parameter set conflict
    ├── 03-select-onchange.ps1   # Cascading select with onChange
    └── 04-ps51-gotcha.md        # PS 5.1 $_ contamination explained
```

## Tech stack

| Component | Version |
|-----------|---------|
| Pode | 2.12.1 |
| Pode.Web | 0.8.3 |
| PowerShell | 5.1 (Windows) / 7+ (cross-platform) |
| Frontend | Bootstrap + jQuery + Chart.js (bundled with Pode.Web) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
