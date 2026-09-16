---
name: converging
description: Assess the current codebase against the feature's design spec and implementation plan, then append any remaining unbuilt work as new tasks to the plan so execution can complete it. Run manually via /converging after superpowers:executing-plans or superpowers:subagent-driven-development has run on the current plan.
---

## User Input

The text after `/converging` (if any) is the user input. It may contain paths to the spec and/or plan files and context for prioritization.

You **MUST** consider the user input before proceeding (if not empty).

## Goal

Close the gap between what a feature's specification and plan call for and what the
codebase currently implements. Read the spec and the plan as the **sole source of intent**
(with the constitution as governing constraints), assess the current state of the code,
determine which requirements, acceptance criteria, plan decisions, and existing tasks are
unmet, incomplete, or only partially satisfied, and **append each piece of remaining work
as a new, traceable task** at the bottom of the plan so that
`superpowers:executing-plans` / `superpowers:subagent-driven-development` can complete it.
This skill MUST run only after the plan has been executed at least once, and after
`superpowers:writing-plans` has produced a complete plan.

This is **not** a diff tool and does **not** track changes. It assesses the present state
of the code relative to the feature's artifacts — no git, no branch comparison, no history.

## Operating Constraints

**APPEND-ONLY, NEVER REWRITE**: The skill's **only** write is appending a new
`## Convergence N` section to the plan. It MUST NOT:

- modify the spec in any way;
- rewrite, renumber, reorder, or delete any existing task (including tasks from a prior
  Convergence section);
- modify, create, or delete any application code — completing the appended tasks is the
  job of `superpowers:executing-plans` / `superpowers:subagent-driven-development`.

When the codebase already satisfies everything, the skill MUST leave the plan
**byte-for-byte unchanged** (no empty Convergence header) and report a clean result.

**Constitution Authority**: The global constitution (`~/.claude/constitution.md`) is
**non-negotiable**. Code that violates a MUST/NEVER principle is the highest-severity
finding and produces a corresponding remediation task. The project's `CLAUDE.md` (if
present) is treated as an addition to the constitution with the same authority. If the
constitution is an unfilled template, skip constitution checks gracefully rather than
failing.

## Execution Steps

### 1. Initialize Convergence Context

Derive absolute paths:

- SPEC = path from user input, otherwise the `**Spec:**` path referenced in the plan header, otherwise the most recently modified file in `docs/superpowers/specs/` (or the user's configured spec location)
- PLAN = path from user input, otherwise the most recently modified file in `docs/superpowers/plans/` (or the user's configured plan location)
- CONSTITUTION = `~/.claude/constitution.md` (if present and not an unfilled template)
- CLAUDE = `CLAUDE.md` in the project root (if present)

If the spec or the plan is missing, STOP with a clear, actionable message naming the
prerequisite skill to run (`superpowers:brainstorming` for a missing spec,
`superpowers:writing-plans` for a missing plan). Do not produce partial output.

### 2. Load Artifacts (Progressive Disclosure)

Load only the minimal necessary context from each artifact:

**From the spec:**

- Functional Requirements
- Success Criteria — include only items requiring buildable work; exclude
  post-launch outcome metrics and business KPIs
- User Stories and their Acceptance Scenarios
- Edge Cases (if present)
- Clarifications (if present)

**From the plan header:**

- Goal, Architecture/stack choices and technical decisions
- Tech Stack
- Global Constraints
- Data Model references

**From the plan tasks (`### Task N: ...` sections):**

- Task numbers (to compute the next task number) and existing `## Convergence N` sections (to compute the next convergence number)
- Descriptions, `**Files:**` blocks (Create / Modify / Test paths), `**Interfaces:**` blocks
- Step checkbox state (`- [ ]` / `- [x]`)

**From constitution (if not an unfilled template):**

- Principle names and MUST/SHOULD/NEVER normative statements from `~/.claude/constitution.md` and `CLAUDE.md`

### 3. Build the Intent Inventory

Create an internal model (do not echo raw artifacts):

- **Requirements inventory**: one stable key per functional requirement / success
  criterion / user-story acceptance scenario (use explicit ids like FR-### when present,
  otherwise an imperative-phrase slug, e.g. `US1/AC2` or `user-can-upload-file`), plus the
  plan decisions and constitution principles that impose buildable obligations.
- **Code-scope map**: from the file paths named in the plan's `**Files:**` blocks, plus a
  keyword search for the concepts each requirement describes, derive the set of source
  files and components in scope for assessment. Bound the assessment to these — do **not**
  infer scope beyond what the artifacts define.

### 4. Assess the Codebase and Classify Findings

For each item in the intent inventory, inspect the current code in scope and produce a
`Finding` only where there is a gap. Classify every finding by **gap type**:

- **`missing`**: the required work is absent from the code entirely.
- **`partial`**: the work exists but does not yet fully satisfy the requirement /
  acceptance criterion / plan decision.
- **`contradicts`**: the code does something that conflicts with stated intent or a
  constitution MUST/NEVER principle.
- **`unrequested`**: the code contains work not called for by the spec or plan
  (surfaced for awareness — converging does **not** delete code, it only appends a task to
  review/justify or remove it).

Each `Finding` records: a stable id, the `source-ref` it traces to, the `gap-type`, a
severity, and a short human-readable description with the evidence (the file/area observed).

**Edge cases:**

- **Little or no code yet**: treat the entire specified scope as `missing` remaining work
  rather than failing.
- **Nothing remains**: produce zero findings and follow the converged branch in Step 7.

### 5. Assign Severity

- **CRITICAL**: violates a constitution MUST/NEVER principle, or a `missing`/`contradicts`
  gap that blocks baseline functionality of a core user story.
- **HIGH**: a `missing` or `partial` gap on a core functional requirement or acceptance
  criterion.
- **MEDIUM**: a `partial` gap on a secondary requirement, or an `unrequested` addition with
  unclear justification.
- **LOW**: minor partial gaps, polish, or low-risk `unrequested` additions.

### 6. Present the In-Session Findings Summary

Before appending anything, output a compact, severity-graded summary (no file writes yet):

## Convergence Findings

| ID | Gap Type | Severity | Source | Evidence | Remaining Work |
|----|----------|----------|--------|----------|----------------|
| F1 | missing  | HIGH     | FR-008 | Example: no CSV export function found in src/export/ | Add CSV export |

**Summary metrics:**

- Requirements / acceptance criteria checked
- Plan decisions checked
- Constitution principles checked (or "skipped — template")
- Findings by gap type (missing / partial / contradicts / unrequested)
- Findings by severity

### 7. Append Convergence Tasks (or report converged)

**If there are one or more actionable findings** (`tasks_appended` outcome):

Append to the **end** of the plan, per the append contract:

1. Scan all existing `### Task N` headings; let `M` be the maximum. Determine the next
   convergence number `C` (highest existing `## Convergence N` + 1, or 1 if none).
2. Write a single new section header `## Convergence C`.
3. Emit one task per actionable finding, ordered CRITICAL/HIGH first, numbered
   `Task M+1, Task M+2, …`. Each task MUST follow the full task structure from
   `superpowers:writing-plans` so that it is directly executable:

   ````markdown
   ### Task M+1: <Component Name> — per <source-ref> (<gap-type>)

   **Files:**
   - Create: `exact/path/to/file.py`
   - Modify: `exact/path/to/existing.py:123-145`
   - Test: `tests/exact/path/to/test.py`

   **Interfaces:**
   - Consumes: [exact signatures this task uses from existing code or earlier tasks]
   - Produces: [exact function names, parameter and return types later tasks rely on]

   - [ ] **Step 1: Write the failing test**

   ```python
   def test_specific_behavior():
       ...
   ```

   - [ ] **Step 2: Run test to verify it fails**

   Run: `<exact command>`
   Expected: FAIL with "<expected message>"

   - [ ] **Step 3: Write minimal implementation**

   ```python
   ...
   ```

   - [ ] **Step 4: Run test to verify it passes**

   Run: `<exact command>`
   Expected: PASS

   - [ ] **Step 5: Commit**

   ```bash
   git add <files>
   git commit -m "<message>"
   ```
   ````

   `<source-ref>` traces the task to its origin: e.g. `FR-003`, `SC-002`,
   `US1/AC2`, `plan: storage decision`, `Constitution II`.

   `<gap-type>` is one of `missing`, `partial`, `contradicts`, `unrequested`.

   Constitution-violation tasks MUST be emitted first and described as
   `CRITICAL` in the task name.

   For `unrequested` findings, the task is to review and either justify (document in the
   spec via `/clarifying`) or remove the addition; it still follows the full structure.

   No placeholders: every step must contain the actual content an engineer needs
   (real code, real commands, real expected output), as required by
   `superpowers:writing-plans`.
4. Never reuse or renumber existing task numbers. If a prior Convergence section exists,
   add a new, separately-numbered one below it — do not touch the old one.

**If there are no actionable findings** (`converged` outcome):

- Do **not** modify the plan at all — no empty Convergence header.
- Report: **"✅ Converged — the implementation satisfies the spec and plan."**
- Include the summary counts of what was checked.

### 8. Provide Next Actions (Handoff)

- On `tasks_appended`: state how many tasks were appended under which Convergence section,
  and recommend running `superpowers:executing-plans` or
  `superpowers:subagent-driven-development` on those tasks; note that a follow-up
  `/converging` run will find fewer or no remaining items.
- On `converged`: recommend proceeding to `superpowers:verification-before-completion`,
  then `superpowers:requesting-code-review` and `superpowers:finishing-a-development-branch`.
  No further execution pass is needed for this feature's specified scope.
