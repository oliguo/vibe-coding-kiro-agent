---
name: tasks-template
purpose: Seed content for tasks.md files
---

# [feature_name] Implementation Tasks

> Status markers (best practice):

- [ ] pending — task identified but not started
- [-] processing — task in active work (in-progress)
- [x] completed — task finished and validated

Each task entry SHOULD include small metadata (optional but recommended):

- owner: @github-username or name
- estimate: 1h / 30m / 2d
- branch: feature/[feature_name]-<task-short>
- started_by: @github-username
- started_at: 2025-08-15T12:34:00Z
- completed_by: @github-username
- completed_at: 2025-08-15T13:10:00Z
- tests: brief description / test file(s)
- notes: short notes or blockers

Example task list with statuses and metadata:

1. [ ] Scaffold module structure [refs: 1.1]
   - owner: @dev
   - estimate: 1h
   - branch: feature/[feature_name]-scaffold
   - tests: none (smoke)
   - Notes: create folders/files: src/, tests/

2. [ ] Implement core logic [refs: 2.1]
   - owner: @dev
   - estimate: 3h
   - branch: feature/[feature_name]-core
   - tests: unit tests for main functions
   - Notes: implement functions/classes: Foo, Bar

3. [ ] Integrations [refs: 3.x]
   - owner: @dev
   - estimate: 2h
   - branch: feature/[feature_name]-integrations
   - tests: integration tests: test_integration.py
   - Notes: wire interfaces to external API

4. [ ] Error handling & edge cases [refs: 4.x]
   - owner: @dev
   - estimate: 1h
   - tests: edge case tests
   - Notes: add guards and fallbacks

5. [ ] Docs & cleanup
   - owner: @dev
   - estimate: 30m
   - Notes: README snippets, comments, tidy up

Guidelines for Copilot/agents and humans:

- After generating `tasks.md`, the agent SHOULD ask: "Which task would you like me to start now?" and list tasks with their current status.
- Upon explicit user approval of a task, the agent SHOULD:
  1. Update the selected task status to `[-] processing` and add `started_by`/`started_at` metadata (timestamp in ISO8601 UTC).
  2. Create the suggested branch locally (or instruct the user to create it) and run the minimal test(s) described.
  3. Implement the task steps (produce code snippets, tests) and run tests; report failures and ask for guidance if blocked.
  4. When tests pass and implementation is complete, update the task status to `[x] completed`, set `completed_by`/`completed_at`, and include a short commit note.
  5. Push the branch and open a PR (or ask the user to) if appropriate; the agent should propose a PR title and body.

- The agent MUST request explicit approval before making any commits, pushing branches, or opening PRs in the user's repo. If the agent cannot perform git operations, it SHOULD provide a precise step-by-step command sequence for the user.

- Keep task updates small and incremental. After each status update, the agent SHOULD print a one-line summary and the updated task block.

This template favors clear ownership, small tasks, and an explicit lifecycle so Copilot can orchestrate work confidently while requiring user approval for side-effects.

