# Contributing

Thanks for your interest in improving the Pode.Web agent!

## How to contribute

1. **Fork** the repository
2. Create a **feature branch**: `git checkout -b feature/your-improvement`
3. Make your changes
4. **Test** the agent with Claude Code: `claude --plugin-dir .` or copy to `~/.claude/agents/`
5. Submit a **Pull Request** with a clear description

## What to contribute

- **New gotchas**: Found a Pode.Web or PS 5.1 bug not covered? Add it to the agent prompt and document it in `docs/`
- **New patterns**: Have a reusable page pattern? Add it to `examples/`
- **Bug fixes**: If the agent generates incorrect code for a specific scenario, fix the prompt
- **Documentation**: Improve examples or add new ones

## Guidelines

- Keep the agent prompt under 30,000 characters (Claude Code limit)
- All code must be **PS 5.1 compatible** unless explicitly marked as PS 7+ only
- Test your changes with at least one real Pode.Web scenario
- Follow the existing formatting style in the agent `.md` file

## Reporting issues

Open a [GitHub Issue](https://github.com/michelesant82-beep/claude-code-podeweb-agent/issues) with:

- The prompt you gave to the agent
- The incorrect code it generated
- The expected correct code
- Your Pode.Web and PowerShell versions
