---
description: Kiro spec workflow guardrails and formatting.
applyTo: "**"
---

# Using with GitHub Copilot Chat
- In VS Code, select the "Kiro-Spec-Agent" chat mode in Copilot Chat.
- See `COPILOT.md` for a short Copilot playbook and `.github/prompts/copilot-recipes.md` for reusable prompts.

# Requirements phase
- Infer a short kebab-case {feature_name} from the user idea.
- Before creating .kiro/specs/{feature_name}/requirements.md, prompt the user: “Do you want to create the requirements file now?” Only create the file after explicit user confirmation. Note: specs are stored at the repository root under `.kiro/specs`; the optional `subroot` recorded in `.kiro/kiro-config.json` is used by tools that generate program files.
- When creating requirements.md, seed with .github/templates/kiro-requirements-template.md replacing [feature_name].
- Include:
  - Introduction (feature summary)
  - Hierarchical numbered requirements
  - For each: a user story (“As a [role], I want [feature], so that [benefit]”)
  - EARS acceptance criteria list (WHEN/IF… THEN system SHALL…)
- Consider edge cases, UX, technical constraints, success criteria.
- Ask: “Do the requirements look good? If so, we will create the requirements.md file and move on to the design.”
- Do not proceed without explicit approval (e.g., VS Code prompt and user clicks allow).
 - Success criteria: clear problem framing, numbered requirements, user stories, EARS acceptance criteria, non-functionals, out-of-scope, dependencies/risks.
 - Quality Gates: content validation PASS/FAIL with one-line reason; build/lint/tests N/A.
 - After creation, run scripts/kiro-spec-validate.sh {feature_name} requirements and report PASS/FAIL.

# Design phase
- Before creating .kiro/specs/{feature_name}/design.md, prompt the user: “Do you want to create the design file now?” Only create the file after explicit user confirmation. Note: specs are stored at the repository root under `.kiro/specs`.
- When creating design.md, seed with .github/templates/kiro-design-template.md replacing [feature_name].
- Perform targeted research with #fetch or #search; summarize key findings inline.
- Sections:
  - Overview
  - Architecture
  - Components and Interfaces
  - Data Models
  - Error Handling
  - Testing Strategy
  - (Optional) Diagrams in Mermaid where helpful
- Ask: “Does the design look good? If so, we will create the design.md file and move on to the implementation plan.”
- Do not proceed without explicit approval (e.g., VS Code prompt and user clicks allow).
 - Success criteria: covers overview, architecture, components/interfaces, data models, error handling, testing strategy, traces to requirements; cites any research sources.
 - Quality Gates: content validation PASS/FAIL with one-line reason; build/lint/tests N/A.
 - After creation, run scripts/kiro-spec-validate.sh {feature_name} design and report PASS/FAIL.

# Tasks phase
- Before creating .kiro/specs/{feature_name}/tasks.md, prompt the user: “Do you want to create the tasks file now?” Only create the file after explicit user confirmation. Note: specs are stored at the repository root under `.kiro/specs`.
- When creating tasks.md, seed with .github/templates/kiro-tasks-template.md replacing [feature_name].
- Convert design into a coding-only, TDD-oriented, incremental plan:
  - Simple numbered checklist; optional one extra level (1.1, 1.2).
  - Each step: clear coding objective; any notes as sub-bullets.
  - Reference granular requirement IDs (e.g., 1.2, 3.1).
  - Steps must be actionable and build on prior steps; avoid big jumps.
  - Exclude non-coding activities (UAT, deployment, metrics, etc.).
- Ask: “Do the tasks look good? If so, we will create the tasks.md file.”
- Stop after approval and inform how to start executing tasks later.
 - Success criteria: coding-only, incremental, references requirement IDs, minimal tests suggested; excludes non-coding steps.
 - Quality Gates: content validation PASS/FAIL with one-line reason; build/lint/tests N/A.
 - After creation, run scripts/kiro-spec-validate.sh {feature_name} tasks and report PASS/FAIL.

# Task execution reminders
- Read requirements.md, design.md, tasks.md first.
- Only execute one task at a time; stop for review after each.
- If task has sub-tasks, start with them first.

## Implementation flow and decision aids
- TDD flow: Understand → Test (red) → Implement (green) → Refactor → Commit.
- Max 3 tries rule: after three targeted attempts on a blocker, pause; write a brief failure note and consider alternatives.
- Decision filter: choose options that improve testability, readability, consistency, simplicity, and reversibility.
- Definition of Done for coding steps: passing tests/validators, no lint warnings, clear commits, and no dangling TODOs without references.
