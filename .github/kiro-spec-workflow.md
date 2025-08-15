# Kiro Spec Workflow (VS Code)

A quick guide for running the spec-driven flow with Kiro-Spec-Agent, using gated file creation, templates, and the validator.

See also: `COPILOT.md` for a concise Copilot Chat guide and playbook, and `.github/prompts/copilot-recipes.md` for ready-to-use prompts.

In VS Code Copilot Chat, select the "Kiro-Spec-Agent" chat mode from the mode picker (if it’s not already selected).

## Flow overview
1) Requirements → 2) Design → 3) Tasks
- After each phase output, you’ll be asked to approve creating the file for that phase.
- VS Code will prompt you; click Allow to proceed.
- After creation, the validator runs and prints a one-line Quality Gates result.

## Exact prompts (gated file creation)
- Requirements: "Do the requirements look good? If so, we will create the requirements.md file and move on to the design."
- Design: "Does the design look good? If so, we will create the design.md file and move on to the implementation plan."
- Tasks: "Do the tasks look good? If so, we will create the tasks.md file."

Before any file is written, the agent asks: "Do you want to create the file for this phase?" It proceeds only after your approval.

## Templates mapping
When creating files, content is seeded from:
- Requirements → .github/templates/kiro-requirements-template.md
- Design → .github/templates/kiro-design-template.md
- Tasks → .github/templates/kiro-tasks-template.md

The placeholder [feature_name] is replaced with your inferred kebab-case feature name.

## Validator
Script: scripts/kiro-spec-validate.sh

Usage:
- scripts/kiro-spec-validate.sh <feature_name> [phase]
- phase: requirements | design | tasks | all (default: all)

Exit codes:
- 0 = PASS
- 1 = FAIL (prints brief reasons)

Output example:
- "Quality Gates: content validation PASS — requirements: PASS (5/5 checks) design: PASS (6/6 checks) tasks: PASS (4/4 checks)"
- "Quality Gates: content validation FAIL — requirements: missing file | design: PASS (5/6 checks)"

VS Code Task:
- Run: Terminal → Run Task… → "Kiro: Validate Spec" (feature + phase) or "Kiro: Validate Latest Spec" (phase only).
- Latest Spec uses the most recently updated folder in .kiro/specs/.

## Common pitfalls
- No VS Code approval: files won’t be created until you click Allow.
- Wrong feature name: files are created under .kiro/specs/<feature_name>/; use the same name when running the validator.
- Weak content: validator flags missing sections (e.g., no EARS criteria or user stories). Update the file and re-run.

## Success criteria (summary)
- Requirements: intro/summary, numbered requirements, user stories, EARS acceptance criteria, NFRs, edge cases, out-of-scope, dependencies/risks.
- Design: overview, architecture, components/interfaces, data models, error handling, testing strategy; cite any research.
- Tasks: coding-only, incremental, references requirement IDs; include minimal tests per step.

## Practical tips
- Work TDD: write a small failing test before code; then make it pass and refactor.
- If stuck after 3 focused attempts, step back and reassess alternatives; don’t thrash.
- Prefer solutions that are easy to test and read; match existing patterns.
- Keep commits small and intentional; explain the “why”.
- Don’t carry TODOs without an issue/ID.
