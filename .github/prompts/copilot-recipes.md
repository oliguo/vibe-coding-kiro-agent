# Copilot Chat Recipes (VS Code)

Use these prompts with Copilot Chat for consistent, automated coding.

## Implement a change (TDD)
Prompt:
- Task: [one sentence]
- Files likely involved: #file1, #file2
- Please: 1) write a minimal failing test, 2) implement smallest code to pass, 3) refactor, 4) show a compact diff summary.
- After edits, run quick validation and report: Build/Lint/Tests status (or N/A) and any errors.
 - If the workspace contains `.kiro/kiro-config.json` with a `subroot`, confirm that generated program files should go under that subroot (e.g., `app/`). Ask for explicit approval before writing outside it.

## Spec workflow (gated)
Prompt:
- Feature idea: [short]
- Phase: Requirements/Design/Tasks.
- Propose output first. Then ask: “Do you want to create the file for this phase?”
- After I approve, seed from templates and run scripts/kiro-spec-validate.sh {feature_name} <phase>. Include “Quality Gates: … PASS/FAIL”.

Exact confirmations:
- Requirements: “Do the requirements look good? If so, we will create the requirements.md file and move on to the design.”
- Design: “Does the design look good? If so, we will create the design.md file and move on to the implementation plan.”
- Tasks: “Do the tasks look good? If so, we will create the tasks.md file.”

## Refactor safely
Prompt:
- Goal: Refactor [function/class] for readability/testability without behavior change.
- Constraints: keep public APIs; add/adjust tests as needed.
- Steps: small commits, run tests after each.
- Report: what changed and why; risks; follow-ups.

## Self-review pass
Prompt:
- Do a focused code review on the last edits.
- Check: missing tests, edge cases, error handling, naming, consistency, dead code.
- Suggest concrete fixes; then apply them.

## Stuck after 3 attempts
Prompt:
- I’m stuck on [issue]. I’ve tried [attempts] with errors [messages].
- Please: document failures, suggest 2–3 alternatives with trade-offs, question assumptions, and propose a simpler path.

## Decision framework check
Prompt:
- Given two approaches [A] and [B], evaluate against: testability, readability, consistency, simplicity, reversibility.
- Recommend one and justify.
