# Development Guidelines (Copilot Aid)

Guidance for using GitHub Copilot Chat effectively in this repo.

## Philosophy
- Incremental progress over big bangs: ship small changes that build and test.
- Learn from existing code: scan patterns before changing things.
- Pragmatic over dogmatic: adapt to this project’s reality.
- Clear intent over clever code: boring > magical.

## Process
### Planning & Staging
Break work into 3–5 stages and keep an IMPLEMENTATION_PLAN.md with:
- Goal and success criteria for each stage
- Minimal tests to add
- Status (Not Started/In Progress/Complete)

Remove the plan when done.

### Implementation Flow (TDD)
1. Understand: review code and constraints
2. Test: write a failing test (red)
3. Implement: smallest code to pass (green)
4. Refactor: clean with tests green
5. Commit: small, clear message focusing on “why”

### When Stuck (max 3 attempts)
- Document failures: what you tried, exact errors, suspected cause
- Research 2–3 alternatives and trade-offs
- Question assumptions; split the problem; try simpler approach
- Only then try a different angle (API/pattern)

## Technical Standards
- Composition over inheritance; inject dependencies
- Interfaces over singletons; enable testing
- Explicit over implicit data flow
- Test-driven where possible; never disable tests

## Code Quality
Every commit should:
- Build/compile and pass tests/validators
- Include tests for new behavior
- Follow formatter/linter settings with no warnings
- Explain intent in the commit message

## Error Handling
- Fail fast with descriptive messages
- Include context for debugging
- Handle at the right boundary
- Never swallow exceptions silently

## Decision Framework
Prefer options that maximize:
1) Testability 2) Readability 3) Consistency 4) Simplicity 5) Reversibility

## Quality Gates
Definition of Done:
- [ ] Tests written and passing
- [ ] No linter/formatter warnings
- [ ] Follows project conventions
- [ ] Clear commit messages
- [ ] Matches the plan
- [ ] No TODOs without issue IDs

## Copilot Chat playbook
- Copilot reads `.github/**` instruction files; we keep them authoritative.
- Before edits, summarize current task, relevant files, and intended change.
- After edits, validate: build/lint/tests or spec validator; report PASS/FAIL.
- Keep messages concise; include only deltas after tool runs.
- Ask for explicit approval before creating spec/design/tasks files; seed from templates and run validator.

## Project Integration
- Look for similar features/components first
- Reuse existing utilities and test patterns
- Use the project’s build/test tools; avoid introducing new ones without strong reason
