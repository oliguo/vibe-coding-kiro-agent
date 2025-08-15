# Vibe Coding with GitHub Copilot (Kiro-style)

A minimal toolkit to spin up a new workspace and get a smart, spec-driven Copilot Chat experience like Kiro AI IDE.

## Quickstart
### Prerequisites
- VS Code with GitHub Copilot and GitHub Copilot Chat extensions.
- Optional for auto-install: VS Code `code` CLI available in PATH (Command Palette → “Shell Command: Install 'code' command in PATH”).

1) Clone this repo (or download and place it somewhere accessible).
2) Bootstrap a new workspace using the script:

```bash
# From this repo root
scripts/kiro-spec-bootstrap.sh --target "/path/to/your/new-workspace" --feature sample-feature --subroot app --install-extensions --force
```

3) Open the target workspace in VS Code.
- Accept recommended extensions (GitHub Copilot + Copilot Chat) if prompted.
- VS Code Tasks: open the Command Palette (Cmd+Shift+P or F1) → "Run Task" → "Kiro: Validate Spec" or "Kiro: Validate Latest Spec".
- Copilot Chat: choose the "Kiro-Spec-Agent" chat mode in the mode picker.

## How it works
- Instruction files in `.github/**` guide Copilot:
  - `copilot-instructions.md` — repo-wide rules (TDD, 3-attempt rule, decision filter, DoD, playbook)
  - `instructions/kiro-spec.instructions.md` — gated spec phases (requirements, design, tasks)
  - `chatmodes/Kiro-Spec-Agent.chatmode.md` — the chat mode for spec-driven work
  - `prompts/kiro-run-spec.prompt.md` — launch prompt for feature specs
  - `prompts/copilot-recipes.md` — reusable prompts for Copilot Chat
  - `templates/*` — seed content for requirements/design/tasks
- Validators in `scripts/` enforce Quality Gates for planning docs.
- `COPILOT.md` is a short dev/agent guide tailored to Copilot.

## Typical flow
- Start Copilot Chat in the Kiro-Spec-Agent mode.
- Share a feature idea; go through Requirements → Design → Tasks.
- After approval, files are created from templates and validated.
- For coding, use TDD prompts in `prompts/copilot-recipes.md`.

## Notes
- We can’t force-select the chat mode programmatically; select "Kiro-Spec-Agent" manually the first time.
- The bootstrap script enables Copilot instruction files and copies templates, prompts, and validators into your workspace.
- When you pass `--feature <name>` to the bootstrap script it will also seed a starter spec under `.kiro/specs/<name>/` and create an `IMPLEMENTATION_PLAN.md` based on `.github/templates/implementation-plan-template.md`.
- Using `--subroot <dir>` will create the directory under the workspace and record it in `.kiro/kiro-config.json`. Tools and agents should treat this subfolder as the project root for generated code (e.g., `app/`).
 - The `--install-extensions` flag uses the `code` CLI if available; otherwise VS Code will prompt you in the UI.

Note: VS Code tasks (Kiro: Validate Spec / Validate Latest Spec) will look for specs under the configured subroot if `.kiro/kiro-config.json` contains `subroot`.

New task: "Kiro: Validate Latest Spec (Auto)" runs a small helper that auto-detects the latest spec under the subroot and runs the validator without prompting for feature name.

## Troubleshooting
- If files aren’t created, ensure you approved the VS Code prompt.
- If the validator fails, open the reported file, fix missing sections, and re-run the task.

## Continuous Integration
This repo includes a GitHub Actions workflow that runs `scripts/test-bootstrap.sh` on push and pull requests to `main` to ensure the bootstrap flow (including subroot behavior) remains healthy.
