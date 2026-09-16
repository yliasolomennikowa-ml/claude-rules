---
name: analyzing
description: Perform a non-destructive cross-artifact consistency and quality analysis across the design spec and the implementation plan after superpowers:writing-plans has produced the plan. Run manually via /analyzing before executing the plan.
---

## User Input

The text after `/analyzing` (if any) is the user input. It may contain paths to the spec and/or plan files and context for prioritization.

You **MUST** consider the user input before proceeding (if not empty).

## Goal

Identify inconsistencies, duplications, ambiguities, and underspecified items across the two core artifacts (the design spec and the implementation plan) before implementation. This skill MUST run only after `superpowers:writing-plans` has successfully produced a complete plan.

## Operating Constraints

**STRICTLY READ-ONLY**: Do **not** modify any files. Output a structured analysis report. Offer an optional remediation plan (user must explicitly approve before any follow-up editing would be done manually).

**Constitution Authority**: The global constitution (`~/.claude/constitution.md`) is **non-negotiable** within this analysis scope. Constitution conflicts are automatically CRITICAL and require adjustment of the spec or plan—not dilution, reinterpretation, or silent ignoring of the principle. If a principle itself needs to change, that must occur in a separate, explicit constitution update outside `/analyzing`. The project's `CLAUDE.md` (if present) is treated as an addition to the constitution with the same authority.

## Execution Steps

### 1. Initialize Analysis Context

Derive absolute paths:

- SPEC = path from user input, otherwise the `**Spec:**` path referenced in the plan header, otherwise the most recently modified file in `docs/superpowers/specs/` (or the user's configured spec location)
- PLAN = path from user input, otherwise the most recently modified file in `docs/superpowers/plans/` (or the user's configured plan location)
- CONSTITUTION = `~/.claude/constitution.md`
- CLAUDE = `CLAUDE.md` in the project root (optional)

Abort with an error message if SPEC or PLAN is missing (instruct the user to run `superpowers:brainstorming` or `superpowers:writing-plans` respectively).

### 2. Load Artifacts (Progressive Disclosure)

Load only the minimal necessary context from each artifact:

**From the spec:**

- Overview/Context
- Functional Requirements
- Success Criteria (measurable outcomes — e.g., performance, security, availability, user success, business impact)
- User Stories
- Edge Cases (if present)
- Clarifications (if present)

**From the plan header:**

- Goal
- Architecture/stack choices (`**Architecture:**`, `**Tech Stack:**`)
- Global Constraints
- Data Model references
- Technical constraints

**From the plan tasks (`### Task N: ...` sections):**

- Task IDs (Task N) and names
- Descriptions
- `**Files:**` blocks (Create / Modify / Test paths)
- `**Interfaces:**` blocks (Consumes / Produces)
- Step checkboxes (`- [ ]`)

**From constitution:**

- Load `~/.claude/constitution.md` for principle validation
- Load the project's `CLAUDE.md` as additional rules (if it exists)

### 3. Build Semantic Models

Create internal representations (do not include raw artifacts in output):

- **Requirements inventory**: For each Functional Requirement and Success Criterion, record a stable key. Use an explicit identifier (e.g., FR-###, SC-###) as the primary key when present; otherwise derive an imperative-phrase slug for readability (e.g., "User can upload file" → `user-can-upload-file`). Include only Success Criteria items that require buildable work (e.g., load-testing infrastructure, security audit tooling), and exclude post-launch outcome metrics and business KPIs (e.g., "Reduce support tickets by 50%").
- **User story/action inventory**: Discrete user actions with acceptance criteria
- **Task coverage mapping**: Map each task to one or more requirements or stories (inference by keyword / explicit reference patterns like IDs or key phrases)
- **Interface inventory**: For each task, what it Produces and what it Consumes, to check that consumed names are produced by an earlier task
- **Constitution rule set**: Extract principle names and MUST/SHOULD/NEVER normative statements from the constitution and `CLAUDE.md`

### 4. Detection Passes (Token-Efficient Analysis)

Focus on high-signal findings. Limit to 50 findings total; aggregate remainder in overflow summary.

#### A. Duplication Detection

- Identify near-duplicate requirements
- Mark lower-quality phrasing for consolidation

#### B. Ambiguity Detection

- Flag vague adjectives (fast, scalable, secure, intuitive, robust) lacking measurable criteria
- Flag unresolved placeholders (TODO, TKTK, ???, `<placeholder>`, "implement later", "add appropriate error handling", "similar to Task N", etc.)

#### C. Underspecification

- Requirements with verbs but missing object or measurable outcome
- User stories missing acceptance criteria alignment
- Tasks referencing files, components, types, or functions not defined in the spec or in any task of the plan
- Tasks that Consume an interface no earlier task Produces

#### D. Constitution Alignment

- Any requirement or plan element conflicting with a MUST/NEVER principle
- Missing mandated sections, workflow steps, or quality gates from the constitution

#### E. Coverage Gaps

- Requirements with zero associated tasks
- Tasks with no mapped requirement/story
- Success Criteria requiring buildable work (performance, security, availability) not reflected in tasks
- Global Constraints in the plan header not traceable to the spec (or spec constraints missing from Global Constraints)

#### F. Inconsistency

- Terminology drift (same concept named differently across spec and plan)
- Data entities referenced in the plan but absent in the spec (or vice versa)
- Task ordering contradictions (e.g., integration tasks before foundational setup tasks without dependency note)
- Conflicting requirements (e.g., one requires Next.js while other specifies Vue)
- Type/signature drift between tasks (a function named one way in Task 3 and another way in Task 7)

### 5. Severity Assignment

Use this heuristic to prioritize findings:

- **CRITICAL**: Violates a constitution MUST/NEVER principle, missing core spec section, or requirement with zero coverage that blocks baseline functionality
- **HIGH**: Duplicate or conflicting requirement, ambiguous security/performance attribute, untestable acceptance criterion, task consuming an interface nothing produces
- **MEDIUM**: Terminology drift, missing non-functional task coverage, underspecified edge case
- **LOW**: Style/wording improvements, minor redundancy not affecting execution order

### 6. Produce Compact Analysis Report

Output a Markdown report (no file writes) with the following structure:

## Specification Analysis Report

| ID | Category | Severity | Location(s) | Summary | Recommendation |
|----|----------|----------|-------------|---------|----------------|
| A1 | Duplication | HIGH | spec:L120-134 | Two similar requirements ... | Merge phrasing; keep clearer version |

(Add one row per finding; generate stable IDs prefixed by category initial.)

**Coverage Summary Table:**

| Requirement Key | Has Task? | Task IDs | Notes |
|-----------------|-----------|----------|-------|

**Constitution Alignment Issues:** (if any)

**Unmapped Tasks:** (if any)

**Metrics:**

- Total Requirements
- Total Tasks
- Coverage % (requirements with >=1 task)
- Ambiguity Count
- Duplication Count
- Critical Issues Count

### 7. Provide Next Actions

At end of report, output a concise Next Actions block:

- If CRITICAL issues exist: Recommend resolving before `superpowers:executing-plans` / `superpowers:subagent-driven-development`
- If only LOW/MEDIUM: User may proceed, but provide improvement suggestions
- Provide explicit suggestions: e.g., "Run `/clarifying` to resolve the ambiguity in the spec", "Re-run `superpowers:writing-plans` to adjust architecture", "Manually edit the plan to add a task covering 'performance-metrics'"

### 8. Offer Remediation

Ask the user: "Would you like me to suggest concrete remediation edits for the top N issues?" (Do NOT apply them automatically.)

## Operating Principles

### Context Efficiency

- **Minimal high-signal tokens**: Focus on actionable findings, not exhaustive documentation
- **Progressive disclosure**: Load artifacts incrementally; don't dump all content into analysis
- **Token-efficient output**: Limit findings table to 50 rows; summarize overflow
- **Deterministic results**: Rerunning without changes should produce consistent IDs and counts

### Analysis Guidelines

- **NEVER modify files** (this is read-only analysis)
- **NEVER hallucinate missing sections** (if absent, report them accurately)
- **Prioritize constitution violations** (these are always CRITICAL)
- **Use examples over exhaustive rules** (cite specific instances, not generic patterns)
- **Report zero issues gracefully** (emit success report with coverage statistics)

## Context

The user input after `/analyzing`, if any.
