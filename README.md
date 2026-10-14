# claude-plan-limits

**Your Claude plan's usage limits, right in Claude Code's status line.** Free, no account, one small shell script.

```
Opus · 5h 42% (resets 16:00) · week 61% (Thu 11:00)
```

If you're on Claude Pro or Max, Claude Code knows how much of your **5-hour session limit** and **weekly limit** you've used — but you have to type `/usage` to see it. This puts it in the status line, all the time, with the time each limit resets. Above 90 % it adds a ⚠.

## Install (macOS, Linux, Windows with Git Bash)

```sh
mkdir -p ~/.claude
curl -fsSL https://raw.githubusercontent.com/agentower/claude-plan-limits/main/claude-plan-limits.sh -o ~/.claude/claude-plan-limits.sh
```

Then add this to `~/.claude/settings.json` (merge it with what's there):

```json
{ "statusLine": { "type": "command", "command": "sh \"$HOME/.claude/claude-plan-limits.sh\"", "padding": 0, "refreshInterval": 60 } }
```

Start a new Claude Code session. The limits appear after Claude's first reply. With an API key (no plan) there are no plan limits, so it just shows the model.

## Privacy

It reads only what Claude Code hands its status line and prints one line. **It sends nothing anywhere** — unless you use Agentower (below) and have connected it on purpose.

## Optional: see your whole team's limits and agents

[Agentower](https://agentower.com) shows every coding agent your team runs — Claude Code, Codex, Cursor — on one board, with the ones that need someone on top, and everyone's plan limits live. If you've connected Agentower (it creates `~/.agentower/claude-code.env`), this script also sends **just the limit numbers** to your Agentower tower when they change. Delete that file to stop.

## Licence

MIT — see [LICENSE](LICENSE).
