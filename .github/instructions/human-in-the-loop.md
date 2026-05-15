# Human-in-the-Loop Protocol

The pipeline pauses for explicit user confirmation at five checkpoints. **Never bypass these.** "Auto-yes" mode does not exist.

## Mandatory checkpoints

| # | Stage | Question to ask | Default |
|---|---|---|---|
| C1 | Intake | `Run AIDLC for {kind} on '{ticket-or-target}'? [y/N]` | No |
| C2 | Branch | `Create branch '{name}' off '{base}'? [y/N]` | No |
| C3 | Plan | `Plan attached. Proceed with implementation? [y/N]` | No |
| C4 | Review | `All checks passed. Approve and push? [y/N]` | No |
| C5 | PR target | `Target branch for PR? (e.g. main, develop)` | none — must be answered |

## Rules

1. **Default is always NO.** Empty input, anything other than `y` / `yes` (case-insensitive) is treated as rejection.
2. **No timeouts.** The pipeline waits indefinitely. Better to block than to act unilaterally.
3. **No silent re-prompts.** If the user rejects, capture their reason in `runs/<runId>/decisions.log` and either loop back or abort with a clear message.
4. **No batching of decisions.** Do not present C2 and C3 together. Each checkpoint is its own prompt.
5. **Show, then ask.** Before each `[y/N]`, print the concrete artifact the user is approving — branch name, file diff, PR body, etc. Never ask "approve?" without showing what.

## Implementation

All checkpoints go through `scripts/aidlc.sh confirm "<message>"` which:

- Writes to stderr (so prompts don't pollute stdout pipes).
- Reads from `/dev/tty` (so the prompt works even when stdin is redirected).
- Returns exit code 0 on `y` / `yes`, non-zero otherwise.
- Logs the question + answer + timestamp to `.aidlc/runs/<runId>/decisions.log`.

For free-text answers (C5), use `scripts/aidlc.sh ask "<message>" [default]` which prints the answer to stdout.

## Recording decisions

Every decision is appended to `.aidlc/runs/<runId>/decisions.log`:

```
2026-05-15T14:22:01Z C1 "Run AIDLC for feature on 'PROJ-1234'? [y/N]" -> y
2026-05-15T14:22:08Z C2 "Create branch 'aidlc/PROJ-1234-add-search'? [y/N]" -> y
2026-05-15T14:25:33Z C3 "Plan attached. Proceed? [y/N]" -> y
2026-05-15T15:01:12Z C4 "Approve and push? [y/N]" -> y
2026-05-15T15:01:25Z C5 "Target branch for PR?" -> develop
```

This log is attached to the PR body so reviewers can audit the run.
