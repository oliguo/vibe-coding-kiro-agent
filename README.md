# Vibe Coding with GitHub Copilot (Kiro-style)

A compact guide to bootstrap a spec-driven Copilot workspace and run quick helper tasks from VS Code.

## Quickstart (2 steps)

1. Clone this repo.
2. Bootstrap a new workspace:

```bash
# from this repo root
bash scripts/kiro-spec-bootstrap.sh --target "/path/to/new-workspace" --feature sample-feature --subroot app
```

Open the new workspace in VS Code and accept recommended extensions (GitHub Copilot & Copilot Chat).

## Run Tasks (quick commands)

Use Command Palette → Tasks: Run Task to run these safe helpers:

- Kiro: Show Version — runs `scripts/kiro-version.sh`.
- Kiro: Self-Update (dry-run) — runs `scripts/kiro-self-update.sh --dry-run`.
- Kiro: Bump Version (patch, dry-run) — runs `scripts/kiro-bump-version.sh --patch --dry-run`.
- Kiro: Run Command (wrapper) — runs `scripts/kiro-cmd.sh` for interactive subcommands.

Tip: reload the window (Developer: Reload Window) after first bootstrap so VS Code picks up new tasks/snippets.

## Scripts reference (full)

The full scripts reference has been moved to `docs/scripts.md` to keep this README concise. See `docs/scripts.md` for per-script details, arguments, examples, and diagrams.

## Where to start

1. Bootstrap a workspace (`scripts/kiro-spec-bootstrap.sh`).
2. Open it in VS Code and run `Tasks: Run Task` → `Kiro: Show Version` to confirm helpers were installed.
3. Use `Kiro: Run Command (wrapper)` or `Kiro: Self-Update (dry-run)` to explore tooling without risk.

If you want, I can also add example outputs (terminal transcripts) to `docs/scripts.md` for the most-used commands.

## Available VS Code Tasks

These tasks are configured in `.vscode/tasks.json` and are available via Command Palette → Tasks: Run Task. They are intended for local development and quick checks (not a CI integration).

- Kiro: Validate Spec
  - Command: `${workspaceFolder}/scripts/kiro-spec-validate.sh ${input:featureName} ${input:phase}`
  - Use: Validate a specific feature spec (asks for feature name + phase).

- Kiro: Validate Spec (All)
  - Command: `${workspaceFolder}/scripts/kiro-spec-validate.sh ${input:featureName} all`
  - Use: Run full validation for a given feature.

- Kiro: Validate Latest Spec
  - Command: `${workspaceFolder}/scripts/kiro-spec-validate-latest.sh ${input:phase}`
  - Use: Validate the most-recent spec (auto-detects feature) for the chosen phase.

- Kiro: Validate Latest Spec (Auto)
  - Command: `${workspaceFolder}/scripts/kiro-spec-validate-latest-task.sh ${input:phase}`
  - Use: Non-interactive validate-latest helper suitable for automation outside GitHub Actions.

- Kiro: Show Version
  - Command: `${workspaceFolder}/scripts/kiro-version.sh`
  - Use: Print the current Kiro helper tooling `VERSION`.

- Kiro: Self-Update (dry-run)
  - Command: `${workspaceFolder}/scripts/kiro-self-update.sh --dry-run`
  - Use: Preview what a self-update would do without modifying files.

- Kiro: Bump Version (patch, dry-run)
  - Command: `${workspaceFolder}/scripts/kiro-bump-version.sh --patch --dry-run`
  - Use: Preview bumping `VERSION` patch.

- Kiro: Run Command (wrapper)
  - Command: `${workspaceFolder}/scripts/kiro-cmd.sh`
  - Use: Interactive wrapper to run common kiro subcommands (version, self-update, bump, etc.).

## How the tools work (brief)

- `scripts/kiro-spec-bootstrap.sh` — bootstraps a new workspace: copies `.github` instructions, prompts, templates, validators, writes `.vscode` helpers, and optionally seeds `.kiro/specs/<feature>` and `IMPLEMENTATION_PLAN.md`.

- Spec validators (`scripts/kiro-spec-validate.sh`, `kiro-spec-validate-latest.sh`) enforce the repository's quality gates for Requirements/Design/Tasks phases.

- `scripts/kiro-task-update.sh` — atomic helper used by agents to update task status markers in `.kiro/specs/<feature>/tasks.md` when starting/completing work.

- Versioning helpers:
  - `scripts/kiro-version.sh` — prints `VERSION`.
  - `scripts/kiro-bump-version.sh` — bump or set local `VERSION` (supports dry-run).
  - `scripts/kiro-self-update.sh` — safely check remote VERSION and optionally update the workspace (asks before overwriting; supports dry-run).

- `scripts/kiro-cmd.sh` — a small wrapper to run common subcommands quickly (used by the Run Command task and for editor shortcuts/snippets).
