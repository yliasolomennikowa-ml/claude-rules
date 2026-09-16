---
name: clarifying
description: Identify underspecified areas and decisions made without the user in the current design spec by asking up to 5 highly targeted clarification questions and encoding answers back into the spec. Run manually via /clarifying after superpowers:brainstorming has written the spec and before superpowers:writing-plans.
---

## User Input

The text after `/clarifying` (if any) is the user input. It may contain a path to a spec file and/or context for prioritization.

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Goal: Detect and reduce ambiguity, missing decision points, and decisions the model made on the user's behalf in the active design spec, and record the clarifications directly in the spec file.

Note: This clarification workflow is expected to run (and be completed) BEFORE invoking `superpowers:writing-plans`. If the user explicitly states they are skipping clarification (e.g., exploratory spike), you may proceed, but must warn that downstream rework risk increases.

Execution steps:

1. Locate the spec file:
   - If the user input contains a path, use it as `FEATURE_SPEC`.
   - Otherwise, use the most recently modified file in `docs/superpowers/specs/` (or the user's configured spec location) as `FEATURE_SPEC`.
   - If no spec file can be found, abort and instruct the user to run `superpowers:brainstorming` first (do not create a new spec here).

2. Load `~/.claude/constitution.md` for global project principles and governance constraints. **IF EXISTS**: also load the project's `CLAUDE.md` for project-specific constraints. Never ask a question whose answer is already fixed by a constitution rule.

3. Load the current spec file. Perform a structured ambiguity & coverage scan using this taxonomy. For each category, mark status: Clear / Partial / Missing. Produce an internal coverage map used for prioritization (do not output raw map unless no questions will be asked).

   Functional Scope & Behavior:
   - Core user goals & success criteria
   - Explicit out-of-scope declarations
   - User roles / personas differentiation

   Domain & Data Model:
   - Entities, attributes, relationships
   - Identity & uniqueness rules
   - Lifecycle/state transitions
   - Data volume / scale assumptions

   Interaction & UX Flow:
   - Critical user journeys / sequences
   - Error/empty/loading states
   - Accessibility or localization notes

   Non-Functional Quality Attributes:
   - Performance (latency, throughput targets)
   - Scalability (horizontal/vertical, limits)
   - Reliability & availability (uptime, recovery expectations)
   - Observability (logging, metrics, tracing signals)
   - Security & privacy (authN/Z, data protection, threat assumptions)
   - Compliance / regulatory constraints (if any)

   Integration & External Dependencies:
   - External services/APIs and failure modes
   - Data import/export formats
   - Protocol/versioning assumptions

   Edge Cases & Failure Handling:
   - Negative scenarios
   - Rate limiting / throttling
   - Conflict resolution (e.g., concurrent edits)

   Constraints & Tradeoffs:
   - Technical constraints (language, storage, hosting)
   - Explicit tradeoffs or rejected alternatives

   Terminology & Consistency:
   - Canonical glossary terms
   - Avoided synonyms / deprecated terms

   Completion Signals:
   - Acceptance criteria testability
   - Measurable Definition of Done style indicators

   Misc / Placeholders:
   - TODO markers / unresolved decisions
   - Ambiguous adjectives ("robust", "intuitive") lacking quantification

   For each category with Partial or Missing status, add a candidate question opportunity unless:
   - Clarification would not materially change implementation or validation strategy
   - Information is better deferred to planning phase (note internally)

4. **Decisions made without the user.** Perform a second scan of the spec for concrete decisions that are stated as settled (tech stack, storage, data shapes, API formats, auth approach, third-party services, architectural patterns, defaults, limits, etc.). For each decision, determine whether the user actually chose it:
   - **If the brainstorming conversation is available in the current session**: a decision counts as user-made only if the user explicitly chose or confirmed it in the conversation. Anything the model proposed and wrote into the spec without a user answer counts as made without the user.
   - **Otherwise (spec only)**: a decision counts as user-made only if the spec marks it as chosen by the user or it appears under `## Clarifications`. Every other concrete decision counts as made without the user.
   - Add a candidate question for each decision made without the user only if it is critical: it materially impacts architecture, data modeling, task decomposition, test design, UX behavior, operational readiness, or compliance validation, or it would be costly to reverse later. Skip trivial or easily reversible decisions.
   - Assign each such candidate to the closest taxonomy category from step 3 so it participates in the same prioritization and coverage report.

5. Generate (internally) a prioritized queue of candidate clarification questions (maximum 5) from steps 3 and 4 combined. Do NOT output them all at once. Apply these constraints:
    - Maximum of 5 total questions across the whole session.
    - Each question must be answerable with EITHER:
       - A short multiple-choice selection (2–5 distinct, mutually exclusive options), OR
       - A one-word / short-phrase answer (explicitly constrain: "Answer in <=5 words").
    - Only include questions whose answers materially impact architecture, data modeling, task decomposition, test design, UX behavior, operational readiness, or compliance validation.
    - Ensure category coverage balance: attempt to cover the highest impact unresolved categories first; avoid asking two low-impact questions when a single high-impact area (e.g., security posture) is unresolved.
    - Exclude questions already answered, trivial stylistic preferences, or plan-level execution details (unless blocking correctness).
    - Favor clarifications that reduce downstream rework risk or prevent misaligned acceptance tests.
    - If more than 5 candidates remain, select the top 5 by (Impact * Uncertainty) heuristic.

6. Sequential questioning loop (interactive):
    - Present EXACTLY ONE question at a time.
    - **Question writing quality (applies to every question, MC or short-answer):**
       - Lead with `**Question:**` followed by a full interrogative that ends with `?`. The question text before the `?` must make sense on its own.
       - NEVER use a topic label, section heading, or requirement id as the question itself. For example, `Acceptance device/runtime matrix (FR-023)` is INVALID — it is a label, not a question.
       - After the `?`, the only permitted suffix is an optional parenthesized requirement/question id. Exact format: `**Question:** <interrogative>?` or `**Question:** <interrogative>? (FR-023)`. Never put the id before the `?`, and never use the id (alone or with a topic label) as the whole prompt.
       - Immediately after the question line, add one plain-language "Why it matters" sentence (the stake for acceptance or shipping) before the recommendation/options.
       - For a question that comes from step 4 (decision made without the user), the "Why it matters" sentence must state what the spec currently assumes and that the user never chose it.
       - Use everyday wording; introduce jargon only if defined in the same sentence. Self-check: a reader who does not know the project must be able to answer from the Question line alone. Terse is fine; cryptic labels are not.
    - For multiple-choice questions:
       - **Analyze all options** and determine the **most suitable option** based on:
          - Best practices for the project type
          - Common patterns in similar implementations
          - Risk reduction (security, performance, maintainability)
          - Alignment with any explicit project goals or constraints visible in the spec, `~/.claude/constitution.md`, or `CLAUDE.md`
       - Present your **recommended option prominently** at the top with clear reasoning (1-2 sentences explaining why this is the best choice).
       - Format as: `**Recommended:** Option [X] - <reasoning>`
       - Then render all options as a Markdown table:

       | Option | Description |
       |--------|-------------|
       | A | <Option A description> |
       | B | <Option B description> |
       | C | <Option C description> (add D/E as needed up to 5) |
       | Short | Provide a different short answer (<=5 words) (Include only if free-form alternative is appropriate) |

       - After the table, add: `You can reply with the option letter (e.g., "A"), accept the recommendation by saying "yes" or "recommended", or provide your own short answer.`
    - For short-answer style (no meaningful discrete options):
       - Provide your **suggested answer** based on best practices and context.
       - Format as: `**Suggested:** <your proposed answer> - <brief reasoning>`
       - Then output: `Format: Short answer (<=5 words). You can accept the suggestion by saying "yes" or "suggested", or provide your own answer.`
    - After the user answers:
       - If the user replies with "yes", "recommended", or "suggested", use your previously stated recommendation/suggestion as the answer.
       - Otherwise, validate the answer maps to one option or fits the <=5 word constraint.
       - If ambiguous, ask for a quick disambiguation (count still belongs to same question; do not advance).
       - Once satisfactory, record it in working memory (do not yet write to disk) and move to the next queued question.
    - Stop asking further questions when:
       - All critical ambiguities resolved early (remaining queued items become unnecessary), OR
       - User signals completion ("done", "good", "no more"), OR
       - You reach 5 asked questions.
    - Never reveal future queued questions in advance.
    - If no valid questions exist at start, immediately report no critical ambiguities.

7. Integration after EACH accepted answer (incremental update approach):
    - Maintain in-memory representation of the spec (loaded once at start) plus the raw file contents.
    - For the first integrated answer in this session:
       - Ensure a `## Clarifications` section exists (create it just after the highest-level contextual/overview section of the spec if missing).
       - Under it, create (if not present) a `### Session YYYY-MM-DD` subheading for today.
    - Append a bullet line immediately after acceptance: `- Q: <question> → A: <final answer>`.
    - Then immediately apply the clarification to the most appropriate section(s):
       - Functional ambiguity → Update or add a bullet in the functional requirements section.
       - User interaction / actor distinction → Update user stories or actors subsection (if present) with clarified role, constraint, or scenario.
       - Data shape / entities → Update the data model section (add fields, types, relationships) preserving ordering; note added constraints succinctly.
       - Non-functional constraint → Add/modify measurable criteria in the success criteria section (convert vague adjective to metric or explicit target).
       - Edge case / negative flow → Add a new bullet under edge cases / error handling (or create such subsection if the spec has a place for it).
       - Terminology conflict → Normalize term across spec; retain original only if necessary by adding `(formerly referred to as "X")` once.
       - Decision made without the user (step 4) → Replace the assumed decision in place with the user's choice. If the user confirmed the existing decision, leave the text as is; the Clarifications bullet records that the user chose it.
    - If the clarification invalidates an earlier ambiguous statement, replace that statement instead of duplicating; leave no obsolete contradictory text.
    - Save the spec file AFTER each integration to minimize risk of context loss (atomic overwrite).
    - Preserve formatting: do not reorder unrelated sections; keep heading hierarchy intact.
    - Keep each inserted clarification minimal and testable (avoid narrative drift).

8. Validation (performed after EACH write plus final pass):
   - Clarifications session contains exactly one bullet per accepted answer (no duplicates).
   - Total asked (accepted) questions ≤ 5.
   - Updated sections contain no lingering vague placeholders the new answer was meant to resolve.
   - No contradictory earlier statement remains (scan for now-invalid alternative choices removed).
   - Markdown structure valid; only allowed new headings: `## Clarifications`, `### Session YYYY-MM-DD`.
   - Terminology consistency: same canonical term used across all updated sections.

9. Write the updated spec back to `FEATURE_SPEC`.

Behavior rules:

- If no meaningful ambiguities or decisions made without the user are found (or all potential questions would be low-impact), respond: "No critical ambiguities detected worth formal clarification." and suggest proceeding.
- If spec file missing, instruct user to run `superpowers:brainstorming` first (do not create a new spec here).
- Never exceed 5 total asked questions (clarification retries for a single question do not count as new questions).
- Avoid speculative tech stack questions unless the absence blocks functional clarity, or the spec already commits to a tech stack choice the user did not make (step 4).
- Respect user early termination signals ("stop", "done", "proceed").
- If no questions asked due to full coverage, output a compact coverage summary (all categories Clear) then suggest advancing.
- If quota reached with unresolved high-impact categories remaining, explicitly flag them under Deferred with rationale.

Context for prioritization: the user input after `/clarifying`, if any.

## Completion Report

Report completion (after questioning loop ends or early termination):
- Number of questions asked & answered.
- Path to updated spec.
- Sections touched (list names).
- Coverage summary table listing each taxonomy category with Status: Resolved (was Partial/Missing or decided without the user, and addressed), Deferred (exceeds question quota or better suited for planning), Clear (already sufficient), Outstanding (still Partial/Missing but low impact).
- List of remaining decisions made without the user that were not asked about (if any), each with a one-line reason (deferred / low impact / easily reversible).
- If any Outstanding or Deferred remain, recommend whether to proceed to `superpowers:writing-plans` or run `/clarifying` again later post-plan.
- Suggested next step.

## Done When

- [ ] Spec ambiguities and decisions made without the user identified, and clarifications integrated into the spec file
- [ ] Completion reported to user with questions answered, sections touched, and coverage summary
