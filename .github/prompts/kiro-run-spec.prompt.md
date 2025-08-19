---
mode: 'agent'
description: 'Start the Kiro spec workflow from a rough feature idea and generate requirements, design, and tasks with explicit approvals.'
---

Your goal is to run the Kiro spec workflow for ${input:featureIdea:Describe the feature idea}.
- Infer a short kebab-case feature_name based on the idea.
    - Propose, then create or update (only after explicit approval):
     - .kiro/specs/{feature_name}/requirements.md
     - .kiro/specs/{feature_name}/design.md
     - .kiro/specs/{feature_name}/tasks.md
 - Use the instructions in #kiro-spec.instructions.md (applied automatically). Default to macOS + zsh for command examples; adapt if the workspace indicates otherwise.
 - If a `.kiro/kiro-config.json` exists and contains a `subroot` value, prefer that subfolder as the location for generated program files (for example `app/`). Always ask for confirmation before writing files outside the configured subroot. Spec documents themselves are stored at repository root `.kiro/specs` so they are discovered by editor integrations immediately.
- Require explicit user approval before advancing phases.
- Before creating any file, ask: “Do you want to create the file for this phase?” Proceed only after the VS Code prompt is approved.
 - If a spec file already exists, propose a minimal diff to update it and ask for explicit approval before applying changes. Do not create duplicate files.
 - Before any batch of tool calls, include a one-sentence preamble (why/what/outcome), and after ~3–5 calls or >3 file edits, add a compact checkpoint (what ran, key results, what's next).
 - Safety: never overwrite the workspace `.kiro/` directory during updates/bootstraps; preserve it by default. Ask before any destructive operation; prefer dry-runs and emit NDJSON/plain logs when available.
 - Requirements should include user stories, EARS acceptance criteria, edge cases, NFRs, out-of-scope, dependencies/risks.
 - Design should include architecture, components/interfaces, data models, error handling, testing strategy, and cite research when used.
 - Tasks must be coding-only, incremental, and reference requirement IDs with minimal tests per step.
 - Seed new files from .github/templates and replace [feature_name]. After creation, run scripts/kiro-spec-validate.sh {feature_name} <phase> and report PASS/FAIL.
 - When updating task metadata, use ISO8601 local timezone for timestamps.
- Keep outputs concise and developer-focused.

- After creating `tasks.md`, ask: "Which task would you like me to start now?" Show the list with status markers `[ ]`/`[-]`/`[x]`.
- When the user approves a task to start, update the status to `[-] processing`, add `started_by` and `started_at`, and follow the task's steps (run tests, implement, update status to `[x] completed` when done). Always ask for explicit permission before doing git operations (commit/push/PR).

Output:
- A brief confirmation with the inferred feature_name.
- A summary of what was created/updated.
 - A one-line Quality Gates summary for this phase (content validation PASS/FAIL + reason; build/lint/tests N/A).
 - The next question for explicit approval of the current phase (e.g., “Do the requirements look good? If so, we will create the requirements.md file and move on to the design.”).
