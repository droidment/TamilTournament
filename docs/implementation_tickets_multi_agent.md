# Multi-Agent Implementation Tickets: Referee, Assistant, and Public Player Views

## Working Agreements

This file is the primary execution board for the next product expansion. It is intended to be consumed by an orchestrator agent, two builder agents, and one QA agent.

Defaults locked for this execution plan:

- Ticket structure is milestone-based.
- The orchestrator runs at most 2 builder agents in parallel.
- Builder agents must have disjoint write scopes in the same round.
- QA runs smoke checks per completed ticket and milestone regression passes.
- Public player view is fully public by slug.
- Assistants can queue matches and commit scores.
- Referees can submit scores but cannot commit them.
- Assistant or organizer approval is required before referee submissions become official.
- Categories remain in their current storage shape for the first pass, but repository boundaries must preserve future migration flexibility.

Current repo realities that this plan assumes:

- Organizer is the only implemented role today.
- Current routing is organizer-first and minimal.
- Firestore rules are organizer-only today.
- Match completion currently writes official state directly.
- The next delivery needs role-aware routing, score submission vs. score approval separation, and public-safe read paths.

## Agent Roles

### Orchestrator

Responsibilities:

- owns milestone sequencing and dependency tracking
- maintains this board as the source of ticket status truth
- runs at most 2 builder agents in parallel
- assigns only disjoint write scopes
- hands stable contracts to builders before parallel work starts
- integrates builder output when cross-ticket wiring is needed
- routes QA findings back to the correct builder
- keeps the user updated without being prompted

Required user updates:

- milestone start
- builder-a ticket start
- builder-b ticket start
- blocker raised
- QA start
- QA failure
- ticket merged or integrated
- milestone complete

### Builder A

Primary ownership:

- data models
- repositories
- services
- Firestore rules
- role access logic
- public read filtering

### Builder B

Primary ownership:

- routing
- route guards
- shell pages
- page-level UI
- controller wiring
- role-specific interactions

### QA Agent

Primary ownership:

- Playwright smoke checks
- milestone regressions
- visual QA artifacts
- permission regression checks

Constraints:

- QA reports only to the orchestrator
- QA does not edit code
- QA uses browser-testable Flutter web runtime

## Operating Model

### Branch and Handoff Protocol

- Orchestrator opens each milestone and activates only ready tickets.
- Builders work from the current integrated base, not stale milestone branches.
- Orchestrator must not start builder tickets with overlapping write scopes in the same round.
- Shared interfaces must be documented in the stable contract section before builder parallelism begins.
- QA starts only after the orchestrator marks a ticket `qa`.
- QA failures return to the original builder unless the failure is clearly integration-owned.

### Status Vocabulary

- `todo`
- `in_progress`
- `qa`
- `blocked`
- `done`

### QA Vocabulary

- `not_started`
- `smoke_pass`
- `smoke_fail`
- `regression_pass`
- `regression_fail`

## Live Status Board

| ticket_id | owner | status | depends_on | write_scope | qa_status | notes |
|---|---|---|---|---|---|---|
| ORCH-01 | orchestrator | done | none | docs coordination contracts | not_started | Execution board, runbook, and prompt files are active |
| FND-01 | builder-a | in_progress | ORCH-01 | auth/data/models/repos/firestore.rules | not_started | Builder A kickoff in progress |
| FND-02 | builder-b | in_progress | ORCH-01, FND-01 contract | lib/app/router, shell pages, guards | not_started | Builder B kickoff in progress |
| QA-01 | qa | todo | FND-02 | qa artifacts only | not_started | Baseline smoke harness |
| OPS-01 | builder-a | todo | FND-01 | assignment services and match state logic | not_started | Assistant queue and court flow |
| OPS-02 | builder-b | todo | FND-02, OPS-01 contract | assistant pages/controllers | not_started | Assistant floor UI |
| SCORE-01 | builder-a | todo | FND-01 | score submission and approval services | not_started | Officialization split |
| SCORE-02 | builder-b | todo | SCORE-01 | assistant/organizer score inbox UI | not_started | Review and commit UI |
| QA-02 | qa | todo | OPS-02, SCORE-02 | qa artifacts only | not_started | Assistant milestone validation |
| REF-01 | builder-a | todo | FND-01, SCORE-01 | referee query paths and rules | not_started | Referee-scoped access |
| REF-02 | builder-b | todo | REF-01 | referee pages and score entry UI | not_started | Mobile-first submission surface |
| QA-03 | qa | todo | REF-02 | qa artifacts only | not_started | Referee milestone validation |
| PUB-01 | builder-a | todo | FND-01, SCORE-01 | public query services and slug access | not_started | Public-safe read layer |
| PUB-02 | builder-b | todo | PUB-01 | public routes and player pages | not_started | Public player surface |
| QA-04 | qa | todo | PUB-02 | qa artifacts only | not_started | Public milestone validation |

## Write Scope Map

Use this map to keep builder work non-overlapping in the same round.

### Builder A preferred write scope

- `firestore.rules`
- auth access models and providers
- tournament role models
- match domain and state models
- score submission models
- repositories under feature data layers
- service layer additions for access, assignment, submission, approval, public queries

### Builder B preferred write scope

- `lib/app/router/...`
- route guard and shell components
- assistant presentation files
- referee presentation files
- public presentation files
- screen controllers and UI composition

### Orchestrator integration scope

- cross-feature wiring
- shared contract notes in this file
- ticket state updates
- integration checkpoints

## Stable Interface Contracts

These contracts must be treated as locked before builder parallel work begins.

### Contract A: Role model

Tournament-scoped role storage:

```text
tournaments/{tournamentId}/roles/{roleId}
```

Minimum fields:

- `userId`
- `email`
- `displayName`
- `role`
- `isActive`
- `assignedAt`
- `assignedBy`

Supported roles for this build:

- `organizer`
- `assistant`
- `referee`

### Contract B: Public tournament access

Tournament documents gain public access metadata:

- `publicSlug`
- `isPublic`
- `publicStatus`

Category documents gain:

- `isPublished`

Public routes use slug, not raw tournament ID.

### Contract C: Match state expansion

Target operational match states for this build:

- `pending`
- `ready`
- `assigned`
- `called`
- `on_court`
- `score_submitted`
- `completed`
- `held`
- `cancelled`
- `forfeit`

Not every state must ship with full UI in Milestone 1, but the domain and repository design must support them.

### Contract D: Score submission model

New collection:

```text
tournaments/{tournamentId}/scoreSubmissions/{submissionId}
```

Minimum fields:

- `matchId`
- `submittedByUserId`
- `submittedByRole`
- `submittedAt`
- `games`
- `proposedWinnerEntryId`
- `note`
- `approvalStatus`
- `approvedByUserId`
- `approvedByRole`
- `approvedAt`
- `rejectedReason`

Allowed approval states:

- `pending`
- `approved`
- `rejected`

### Contract E: Official result metadata

Match documents gain official result linkage:

- `officialScoreSubmissionId`
- `officializedByUserId`
- `officializedByRole`
- `officializedAt`

Referees never write these fields directly.

### Contract F: Direct assistant entry

Assistant direct score entry must still create a submission record. The assistant path may auto-approve within the same service operation, but must not bypass the submission record.

## Ticket Template

Copy this template for each active ticket handoff.

```md
### TICKET-ID: Title

- Owner type:
- Goal:
- Dependencies:
- Write scope:
- Read scope:
- Deliverables:
- Acceptance criteria:
- QA checks:
- Handoff notes:
```

## Milestone Board

## Milestone 1: Foundation and Contracts

### ORCH-01: Execution Board and Contracts

- Owner type: orchestrator
- Goal: establish execution board, write scopes, branch discipline, and stable contracts for parallel builders
- Dependencies: none
- Write scope: `docs/implementation_tickets_multi_agent.md`
- Read scope: role planning doc, current router, current Firestore rules, current scheduler data flow
- Deliverables:
  - live status table
  - handoff template
  - write scope map
  - stable interface contracts
  - reporting protocol
- Acceptance criteria:
  - builders can start without making interface decisions on their own
  - no milestone ticket starts without a clear owner and non-overlapping write scope
- QA checks:
  - none
- Handoff notes:
  - complete this ticket before any builder parallelism

### FND-01: Role/Access and Score-Submission Data Foundation

- Owner type: builder-a
- Goal: establish role-aware access, public metadata, score submission entity, and domain/repository split between submitted score and official result
- Dependencies: ORCH-01
- Write scope:
  - auth and access models
  - tournament role models
  - score submission models
  - match domain state definitions
  - repository and service changes
  - `firestore.rules`
- Read scope:
  - current tournament, match, and auth flows
  - role planning doc
- Deliverables:
  - tournament role model
  - public slug and publish fields model
  - score submission entity
  - expanded match state model
  - repository/service split for submission vs approval
  - rules for organizer, assistant, referee, and public reads
- Acceptance criteria:
  - no direct referee-to-official-result path remains in design
  - assistant/organizer approval is represented in data and rules
  - public-safe read boundary is representable
- QA checks:
  - permission smoke after routing shells exist
  - repository and service test coverage for role access and state transitions
- Handoff notes:
  - publish any newly added model fields to the stable contract section before builder-b consumes them

### FND-02: Role-Aware Routing and Surface Shells

- Owner type: builder-b
- Goal: create route families and guarded shell surfaces for organizer, assistant, referee, and public access
- Dependencies: ORCH-01, FND-01 stable contracts
- Write scope:
  - `lib/app/router`
  - route guards
  - placeholder shell pages
  - surface entry screens
- Read scope:
  - existing auth gate
  - current organizer routing
  - stable interface contracts in this file
- Deliverables:
  - organizer route family
  - assistant route family
  - referee route family
  - public slug-based route family
  - placeholder shells with guard behavior
- Acceptance criteria:
  - new routes exist without depending on unfinished inner feature work
  - route ownership is clear for later tickets
  - public slug path exists independently of organizer auth
- QA checks:
  - route reachability smoke
  - guard behavior smoke
- Handoff notes:
  - avoid deep feature implementation in this ticket; this ticket is shell-first

### QA-01: Foundation Smoke Harness

- Owner type: qa
- Goal: establish QA runtime, shell-level smoke checks, and baseline screenshots
- Dependencies: FND-02
- Write scope: none
- Read scope:
  - this execution board
  - `playwright-interactive` skill
  - completed shell routes
- Deliverables:
  - smoke inventory for route reachability and role gating
  - baseline desktop and mobile screenshots for organizer, assistant, referee, and public shells
  - reproducible QA notes for runtime startup
- Acceptance criteria:
  - QA can launch the app and exercise shell-level navigation reliably
  - baseline route coverage exists for milestone regressions
- QA checks:
  - run itself
- Handoff notes:
  - report all failures back to orchestrator with owning ticket and repro steps

## Milestone 2: Assistant Operational Flow and Approval Loop

### OPS-01: Match Assignment and Court Queue Services

- Owner type: builder-a
- Goal: add assistant-capable assignment flow and explicit operational state transitions
- Dependencies: FND-01
- Write scope:
  - assignment services
  - repository operations for court queueing
  - match transition validation
- Read scope:
  - current scheduler domain and repository logic
- Deliverables:
  - assistant-capable assignment flow
  - ready, assigned, called, and on-court transitions
  - validation for allowed assistant actions
- Acceptance criteria:
  - assistant actions cannot bypass role rules
  - transitions are explicit and testable
  - queue and court assignment state can drive builder-b UI
- QA checks:
  - unit and repository tests for valid and invalid transitions
- Handoff notes:
  - publish interaction contract for builder-b before UI work starts

### OPS-02: Assistant UI for Queue, Courts, and Match Actions

- Owner type: builder-b
- Goal: provide the assistant floor UI for court flow and match queue management
- Dependencies: FND-02, OPS-01 stable contracts
- Write scope:
  - assistant home
  - live court board UI
  - ready queue UI
  - match detail action UI
- Read scope:
  - assignment contract from OPS-01
  - assistant shell routes
- Deliverables:
  - assistant home
  - live court board
  - ready queue
  - match detail action surface
- Acceptance criteria:
  - assistant can queue a match onto a court from the UI
  - organizer-only setup controls do not leak into assistant UI
  - layout works on tablet and mobile-first widths
- QA checks:
  - assistant floor interaction smoke
  - viewport-fit screenshots
- Handoff notes:
  - keep feature state localized to assistant surface; do not couple to organizer page internals

### SCORE-01: Submission and Approval Services

- Owner type: builder-a
- Goal: implement score submission, approval, rejection, and officialization flows with one auditable pipeline
- Dependencies: FND-01
- Write scope:
  - score submission service
  - score approval service
  - repository operations for officializing match result
  - standings trigger integration
- Read scope:
  - current match scoring and standings logic
- Deliverables:
  - referee submission path
  - assistant or organizer approve/reject path
  - assistant direct-entry auto-approval path using the same submission record
- Acceptance criteria:
  - referee creates pending submissions only
  - assistant or organizer approval makes result official
  - assistant direct entry still writes an auditable submission record
- QA checks:
  - service and repository tests for approve, reject, and auto-approve paths
  - negative tests for unauthorized officialization
- Handoff notes:
  - expose minimal review-state contract for builder-b inbox UI

### SCORE-02: Assistant/Organizer Approval Inbox UI

- Owner type: builder-b
- Goal: provide UI to review, approve, reject, and directly commit scores through the shared submission pipeline
- Dependencies: SCORE-01
- Write scope:
  - assistant score inbox
  - organizer score review surface
  - review panel
  - approve and reject controls
  - direct assistant score entry and commit UI
- Read scope:
  - score review contract from SCORE-01
- Deliverables:
  - pending score inbox
  - review panel
  - approve and reject interactions
  - assistant direct score entry and commit surface
- Acceptance criteria:
  - pending referee submissions can be approved or rejected from the UI
  - assistant direct commit uses the same visible workflow contract
  - result remains unofficial until approved
- QA checks:
  - interaction smoke for approval and rejection flows
  - screenshot evidence for pending and approved states
- Handoff notes:
  - do not create a second non-audited direct-write UI path

### QA-02: Assistant Milestone Smoke and Regression

- Owner type: qa
- Goal: validate assistant operational flow and ensure organizer baseline remains intact
- Dependencies: OPS-02, SCORE-02
- Write scope: none
- Read scope:
  - completed assistant and organizer surfaces
- Deliverables:
  - smoke pass on assignment and score approval flows
  - milestone regression for organizer and assistant surfaces
  - screenshots and repro notes for failures
- Acceptance criteria:
  - no regression to organizer baseline
  - assistant flow works end to end in browser automation
- QA checks:
  - route smoke
  - interaction smoke
  - permission smoke
  - milestone regression
- Handoff notes:
  - classify failures as builder-a, builder-b, or integration-owned

## Milestone 3: Referee Submission Surface

### REF-01: Referee-Scoped Queries and Write Rules

- Owner type: builder-a
- Goal: expose only the intended read and write paths for referee submissions
- Dependencies: FND-01, SCORE-01
- Write scope:
  - referee query/repository layer
  - Firestore rules for referee reads and writes
  - match lookup filtering
- Read scope:
  - score submission model
  - current match assignment metadata
- Deliverables:
  - query path for assigned or current matches
  - rule-safe score-submission-only write path
- Acceptance criteria:
  - referee cannot write official match fields
  - referee cannot change assignment fields
  - referee visibility is limited to the intended lookup surface
- QA checks:
  - negative permission tests
  - repository tests for scoped lookup behavior
- Handoff notes:
  - document any field-level assumptions consumed by referee UI

### REF-02: Referee Mobile-First Submission UI

- Owner type: builder-b
- Goal: build a fast, low-friction referee submission surface optimized for phone widths
- Dependencies: REF-01
- Write scope:
  - referee home
  - match lookup UI
  - score entry UI
  - submission confirmation UI
- Read scope:
  - referee query contract
  - score submission contract
- Deliverables:
  - referee home
  - find-by-court or match-code flow
  - best-of-3 score entry
  - submission confirmation
- Acceptance criteria:
  - score entry is fast on phone-sized viewport
  - successful submission leaves result unofficial until approval
  - only intended match lookup actions are present
- QA checks:
  - mobile-first interaction smoke
  - visual checks at phone viewport
- Handoff notes:
  - prioritize clarity and large touch targets over dense controls

### QA-03: Referee Milestone Smoke and Regression

- Owner type: qa
- Goal: validate referee flow and protect previously completed organizer and assistant behavior
- Dependencies: REF-02
- Write scope: none
- Read scope:
  - all completed role surfaces
- Deliverables:
  - referee submission smoke coverage
  - milestone regression across organizer, assistant, and referee routes
  - failure reports with screenshots
- Acceptance criteria:
  - referee submission path works
  - unauthorized referee actions are blocked
  - assistant approval still finalizes referee-submitted scores correctly
- QA checks:
  - smoke and regression
- Handoff notes:
  - capture both desktop and mobile referee evidence

## Milestone 4: Public Player Surface

### PUB-01: Public Read Model and Slug Access Layer

- Owner type: builder-a
- Goal: expose public-safe official tournament data by slug without leaking internal or pending state
- Dependencies: FND-01, SCORE-01
- Write scope:
  - slug lookup services
  - public query services
  - safe field filtering
  - public read rules
- Read scope:
  - tournament public metadata contract
  - official result metadata
  - current category, standings, match, and court data shape
- Deliverables:
  - public tournament lookup by slug
  - safe queries for categories, standings, courts, results, search, and pair detail
- Acceptance criteria:
  - only official approved data is public
  - no pending submissions, role data, or internal audit data leaks
  - public reads are route-consumable by builder-b without organizer auth coupling
- QA checks:
  - negative read tests for pending and restricted data
  - service coverage for slug lookup and safe result filtering
- Handoff notes:
  - clearly document the public view models consumed by builder-b

### PUB-02: Public Player Views

- Owner type: builder-b
- Goal: build the public player-facing surface that answers core tournament questions quickly
- Dependencies: PUB-01
- Write scope:
  - public home
  - category list and detail pages
  - live court board
  - results feed
  - search
  - pair detail
- Read scope:
  - public query contracts from PUB-01
- Deliverables:
  - public home
  - category list and detail
  - live courts board
  - results feed
  - search
  - pair detail
- Acceptance criteria:
  - all pages are shareable by public slug
  - pages answer where to play, what happened, and what is next
  - layouts are usable on mobile and desktop
- QA checks:
  - public route smoke
  - visual QA on mobile and desktop
  - search interaction smoke
- Handoff notes:
  - do not expose internal operational wording or organizer-only controls

### QA-04: Public Milestone Smoke and Regression

- Owner type: qa
- Goal: validate public player views and ensure the official-state boundary holds after integration
- Dependencies: PUB-02
- Write scope: none
- Read scope:
  - all completed surfaces
- Deliverables:
  - smoke coverage for public pages
  - milestone regression across all role surfaces
  - viewport-fit checks for mobile and desktop public views
  - screenshots and repro notes for failures
- Acceptance criteria:
  - public pages are reachable, readable, and shareable
  - official-state boundary remains intact
  - no regressions in organizer, assistant, or referee views
- QA checks:
  - full milestone smoke and regression
- Handoff notes:
  - include negative confirmation that pending and restricted data did not leak

## QA Workflow

QA uses Playwright against Flutter web in browser-testable mode, not `flutter run -d chrome`.

Recommended runtime:

```bash
flutter run -d web-server --web-hostname localhost --web-port 7357
```

Skill reference:

- [playwright-interactive skill](C:\Users\Raj\.codex\skills\playwright-interactive\SKILL.md)

### QA runtime rules

- Start the Flutter web server in a persistent terminal session.
- Use `localhost` consistently for the local QA URL.
- Maintain a shared QA inventory per milestone before signoff.
- Reuse the same Playwright session where possible.
- Run separate functional and visual QA passes.
- Capture screenshots for the states being signed off.
- Perform explicit viewport-fit checks on relevant surfaces.

### Per-ticket QA

Run these checks after each completed ticket, based on what changed:

- route or shell smoke if routing changed
- role-permission smoke if auth, data access, or rules changed
- interaction smoke for the delivered feature
- screenshots for affected surfaces

### Per-milestone QA

Run these checks after milestone integration:

- regression across all completed role surfaces
- mobile and desktop checks for any new user-facing pages
- negative permission and data leakage checks
- exploratory pass for fragile or interaction-heavy flows

### Required negative checks

- referee cannot commit results
- public cannot see pending submissions
- assistant cannot access organizer-only setup and edit capabilities

### QA outputs to orchestrator

Every QA report must include:

- pass or fail summary
- owning ticket ID
- severity
- exact repro steps
- screenshots
- route or viewport context
- recommendation on whether the failure is builder-a, builder-b, or integration-owned

## Reporting Protocol

The orchestrator posts user-facing updates at these checkpoints:

- milestone kicked off
- builder-a started ticket X
- builder-b started ticket Y
- QA started ticket or milestone validation
- QA failed ticket X with short finding summary
- ticket X merged or integrated
- milestone completed with next milestone queued

Update style requirements:

- keep updates short
- include ticket IDs
- mention blockers immediately
- state which builder owns the next action

## Required Test Layers

Every milestone must leave behind appropriate verification, not just UI completion.

### Automated test expectations

- unit and repository tests for role access
- unit and repository tests for score submission approval and state transitions
- widget or page tests for assistant, referee, and public route shells where practical
- Playwright smoke checks per completed ticket
- Playwright milestone regressions with screenshots

### End-to-end scenarios that must exist by final milestone

- assistant queues a match to a court
- referee submits a score
- assistant approves that score and result becomes official
- assistant directly enters and commits a score through the same submission pipeline
- public player pages reflect only official results after approval

## Assumptions and Notes

- This file is a working execution board, not just a narrative plan.
- The orchestrator is responsible for keeping the user updated without waiting to be asked.
- Builder agents should not be assigned overlapping files in the same round.
- QA does not make code changes.
- Category storage remains as-is for the first pass, but repository and service boundaries must not hard-code that decision into route or UI layers.
- If the team later migrates categories into tournament subcollections, builder-b route and page code should not require major rewrites.
