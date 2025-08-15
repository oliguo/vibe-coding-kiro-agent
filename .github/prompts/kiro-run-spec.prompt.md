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
- Use the instructions in #kiro-spec.instructions.md (applied automatically).
- Require explicit user approval before advancing phases.
- Before creating any file, ask: “Do you want to create the file for this phase?” Proceed only after the VS Code prompt is approved.
 - Requirements should include user stories, EARS acceptance criteria, edge cases, NFRs, out-of-scope, dependencies/risks.
 - Design should include architecture, components/interfaces, data models, error handling, testing strategy, and cite research when used.
 - Tasks must be coding-only, incremental, and reference requirement IDs with minimal tests per step.
 - Seed new files from .github/templates and replace [feature_name]. After creation, run scripts/kiro-spec-validate.sh {feature_name} <phase> and report PASS/FAIL.
- Keep outputs concise and developer-focused.

Output:
- A brief confirmation with the inferred feature_name.
- A summary of what was created/updated.
 - A one-line Quality Gates summary for this phase (content validation PASS/FAIL + reason; build/lint/tests N/A).
 - The next question for explicit approval of the current phase (e.g., “Do the requirements look good? If so, we will create the requirements.md file and move on to the design.”).
