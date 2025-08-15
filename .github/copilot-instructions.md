---
description: Repository-wide standards for Kiro-style spec-assisted development. Applies to all chat.
applyTo: "**"
---

# General guidance
- Use a supportive, concise developer tone. Be decisive and precise.
- Prefer minimal, runnable examples. Check syntax and completeness.
- Replace any PII in examples with placeholders like [email], [name].
- Decline malicious requests. Follow security best practices.
- Prefer test-driven, incremental steps and early validation.

## Implementation flow (TDD-first)
- Understand: scan existing patterns and constraints before coding.
- Test: write a minimal failing test (red) when applicable.
- Implement: write the smallest code to pass (green).
- Refactor: clean up with tests green.
- Commit: small, clear commits explaining the “why”.

## When stuck (max 3 targeted attempts)
- After 3 focused tries on the same issue, stop and reassess:
	- Document what failed (what you tried, errors, suspected cause).
	- Research 2–3 alternatives; compare trade-offs.
	- Question assumptions; consider splitting the problem or a simpler approach.
	- Try a different angle (different API/pattern) only after the above.

## Decision framework
- Prefer approaches that maximize: testability, readability, consistency with the codebase, simplicity, and reversibility.

## Definition of Done (coding work)
- Builds/compiles (if applicable) and passes tests/validators.
- No linter/formatter warnings; follows project conventions.
- Tests added/updated for new behavior.
- Commit messages explain intent (“why”), not just “what”.
- No TODOs without an issue/reference.

## Self-review
- Before wrapping up a change, request a quick code review on the edits (by the agent) to spot missed tests, edge cases, and style issues; then apply fixes.

# Spec-driven development defaults
- Use a 3-phase flow: Requirements → Design → Tasks.
- Always request explicit approval before advancing to the next phase.
- At each phase, before creating any spec, design, or task file, prompt the user: “Do you want to create the file for this phase?”
- For requirements, after presenting the requirements, ask: “Do the requirements look good? If so, we will create the requirements.md file and move on to the design.”
- For design, after presenting the design, ask: “Does the design look good? If so, we will create the design.md file and move on to the implementation plan.”
- For tasks, after presenting the tasks, ask: “Do the tasks look good? If so, we will create the tasks.md file.”
- Only create the file after explicit user confirmation (e.g., VS Code prompt and user clicks allow).
- Requirements: Use user stories and EARS acceptance criteria.
- Design: Include overview, architecture, components/interfaces, data models, error handling, testing strategy; cite research findings inline.
- Tasks: Only coding tasks; discrete steps; each references requirement IDs.
- When creating files, seed from templates in .github/templates/ (requirements/design/tasks) and substitute [feature_name].
- After each file creation, run scripts/kiro-spec-validate.sh {feature_name} <phase> and include the Quality Gates summary in the response.

## Phase success criteria and quality gates
- Requirements (PASS when):
	- Includes intro/feature summary, hierarchical numbered requirements, user stories, EARS acceptance criteria
	- Edge cases, non-functional requirements, constraints, out-of-scope, dependencies/risks captured
	- Concise and testable; avoids implementation details
- Design (PASS when):
	- Overview, architecture, components/interfaces, data models, error handling, testing strategy
	- Cites targeted research sources when used; diagrams optional (Mermaid)
	- Traces to requirements and notes trade-offs/constraints
- Tasks (PASS when):
	- Coding-only, incremental checklist that references requirement IDs
	- Each step has a concrete coding objective and suggests minimal tests (TDD-first)
	- No deployment/UAT/metrics steps

- At the end of each phase, include a brief Quality Gates line: Build/Lint/Tests not applicable in planning; content validation PASS/FAIL with one-line reason.

# Language and style
- Speak like a developer. Avoid fluff. No bold/headers unless clarifying a multi-step answer.
- Use bullet points where it improves readability. Avoid repetition.
- Provide commands for Linux bash where relevant.

# Tools and context
- When referencing workspace items in prompts, prefer #codebase, #<file>, #<folder>, #<symbol> for context.

## Copilot Chat playbook
- Always load repo instructions: they live under .github/** and guide the workflow.
- Use the "Kiro-Spec-Agent" chat mode for spec-driven work; select it from the mode picker if not default.
- Before edits, summarize: current task, relevant files, and intended change.
- After edits, run quick validation: syntax/lint check if available; for planning docs, run the spec validator and include PASS/FAIL.
- Keep messages concise; include only deltas after tool runs; avoid repeating unchanged plans.
- Ask for explicit approval before creating spec/design/tasks files; then seed from templates and run the validator.
