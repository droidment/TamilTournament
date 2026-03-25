# Orchestrator Kickoff Runbook

## Purpose

This runbook is the next operational layer after `docs/implementation_tickets_multi_agent.md`. It gives the orchestrator a concrete start sequence for Milestone 1 and defines how to manage builders and QA without leaving coordination decisions to the moment.

Use this runbook when starting the first execution wave for:

- `ORCH-01`
- `FND-01`
- `FND-02`
- `QA-01`

## Milestone 1 Goal

Deliver the foundation required for all later role-specific views:

- stable execution board and contracts
- role-aware access model
- score submission vs official result separation
- route families and guarded surface shells
- baseline QA harness for shell-level validation

## Orchestrator Responsibilities

The orchestrator must:

- treat `docs/implementation_tickets_multi_agent.md` as the live source of ticket truth
- keep builders on disjoint write scopes
- refuse to start a builder task until contract dependencies are stable
- keep the user updated at every milestone start, ticket start, blocker, QA failure, and milestone completion
- integrate and reconcile cross-ticket assumptions before QA begins

## Start Sequence

### Step 1: Confirm baseline context

Before spawning any builders:

- read `docs/implementation_tickets_multi_agent.md`
- read `docs/role_views_planning.md`
- inspect current router, auth gate, Firestore rules, and scheduler score flow
- confirm builder-a and builder-b write scopes remain disjoint for Milestone 1

Milestone 1 write scope split:

- builder-a:
  - auth and access models
  - domain models
  - repositories
  - services
  - `firestore.rules`
- builder-b:
  - `lib/app/router/...`
  - route guards
  - shell pages
  - placeholder role surfaces

### Step 2: Mark the board

Before work starts:

- mark `ORCH-01` as `in_progress`
- mark `FND-01` as `todo`
- mark `FND-02` as `todo`
- mark `QA-01` as `todo`

### Step 3: Publish milestone kickoff update

Use a short user update with:

- milestone name
- active tickets
- which builder owns what
- what the first integration checkpoint will be

Suggested update:

```text
Milestone 1 is starting. Builder A is taking FND-01 on role/access and score foundations, Builder B is taking FND-02 on routing and shell surfaces after contracts are confirmed, and QA will stay parked for QA-01 until the route shells are integrated.
```

### Step 4: Lock stable contracts

Before builder-b starts, the orchestrator must restate these contracts in the handoff:

- tournament role collection path and role names
- public tournament slug fields
- match status enum target states
- score submission collection path and minimum fields
- official result metadata fields on match documents

If builder-a proposes contract changes, the orchestrator must update the execution board first, then brief builder-b.

## Builder Spawn Order

### Wave 1

Start:

- builder-a on `FND-01`

Do not start builder-b until:

- the orchestrator has copied the stable contracts from the execution board into the `FND-02` handoff

Builder-b may start before builder-a finishes only if the handoff is shell-only and does not depend on unresolved model names beyond the locked contracts.

### Wave 2

Start QA only after:

- `FND-02` is integrated
- shell routes are reachable
- the app builds far enough for route smoke validation

## Builder Handoff Messages

These are ready-to-use task briefs. The orchestrator should adapt only if the board changes.

### Handoff for Builder A (`FND-01`)

```text
You own FND-01 in C:\Users\Raj\Projects\TamilTournament.

Goal:
- establish role-aware access, public metadata, score submission entity, expanded match states, and the repository/service split between submitted score and official result

Constraints:
- do not edit routing or shell presentation files owned by builder-b
- preserve current category storage shape for now
- do not bypass the score submission record for assistant direct entry
- referee must never write official result fields directly

Primary write scope:
- auth and access models
- tournament role models
- score submission models
- match domain state definitions
- repository and service changes
- firestore.rules

Deliverables:
- tournament role model
- public slug and publish fields model
- score submission entity
- expanded match state model
- repository/service split for submission vs approval
- rules for organizer, assistant, referee, and public reads

Acceptance:
- no direct referee-to-official-result path remains
- assistant or organizer approval is represented in data and rules
- public-safe read boundary is representable

You are not alone in the codebase. Do not revert others' changes. Adjust to the current workspace state and report changed files plus any contract changes back to the orchestrator.
```

### Handoff for Builder B (`FND-02`)

```text
You own FND-02 in C:\Users\Raj\Projects\TamilTournament.

Goal:
- create route families and guarded shell surfaces for organizer, assistant, referee, and public player access

Locked contracts:
- roles: organizer, assistant, referee
- public routes use tournament slug
- target route families:
  - /o
  - /a/:tournamentId
  - /r/:tournamentId
  - /p/:publicSlug
- shell work only for this ticket; do not implement deep feature flows yet

Constraints:
- do not edit firestore.rules or repository/service files owned by builder-a
- keep the shell surfaces independent of unfinished feature internals
- public slug routes must not depend on organizer auth flow

Primary write scope:
- lib/app/router
- route guards
- placeholder shell pages
- surface entry screens

Deliverables:
- organizer route family
- assistant route family
- referee route family
- public slug-based route family
- placeholder shells with guard behavior

Acceptance:
- new routes exist without depending on unfinished inner features
- route ownership is clear for later tickets
- public slug path exists independently of organizer auth

You are not alone in the codebase. Do not revert others' changes. Adjust to the current workspace state and report changed files plus any route/guard assumptions back to the orchestrator.
```

### Handoff for QA (`QA-01`)

```text
You own QA-01 in C:\Users\Raj\Projects\TamilTournament.

Goal:
- establish baseline Playwright smoke coverage for Milestone 1 shell routes after FND-02 is integrated

Constraints:
- do not edit code
- report only to the orchestrator
- use browser-testable Flutter web runtime, not flutter run -d chrome
- follow the local Playwright workflow in C:\Users\Raj\.codex\skills\playwright-interactive\SKILL.md

Required runtime:
- flutter run -d web-server --web-hostname 127.0.0.1 --web-port 7357

Deliverables:
- smoke inventory for route reachability and role gating
- baseline desktop and mobile screenshots for organizer, assistant, referee, and public shells
- reproducible startup notes

Acceptance:
- QA can launch the app and exercise shell-level navigation reliably
- baseline route coverage exists for milestone regressions

Report format:
- pass/fail summary
- owning ticket ID
- severity
- exact repro steps
- screenshots
- route or viewport context
- recommendation on whether the issue belongs to builder-a, builder-b, or integration
```

## Integration Checkpoints

### Checkpoint A: After builder-a first pass

The orchestrator verifies:

- new fields or enums do not conflict with the locked contracts
- score submission vs official result split is explicit
- Firestore rules still align with route intent

If contract drift exists:

- pause builder-b if needed
- update the execution board
- send a contract correction message before builder-b continues

### Checkpoint B: After builder-b first pass

The orchestrator verifies:

- route families exist
- shell routes do not import unfinished feature internals too deeply
- public route path is independent of organizer auth shell

### Checkpoint C: Before QA

The orchestrator verifies:

- both builder tickets are integrated
- the app starts successfully enough for route smoke tests
- ticket statuses are updated to move work into `qa`

## Ticket Status Transitions

Use this exact progression unless blocked:

- `todo` -> `in_progress`
- `in_progress` -> `qa`
- `qa` -> `done`
- any state -> `blocked` if a real dependency or integration issue prevents forward progress

### Milestone 1 expected progression

1. `ORCH-01` -> `in_progress`
2. `FND-01` -> `in_progress`
3. `FND-02` -> `in_progress`
4. `ORCH-01` -> `done` once the board, contracts, handoffs, and status protocol are active
5. `FND-01` -> `qa` after integration
6. `FND-02` -> `qa` after integration
7. `QA-01` -> `in_progress`
8. `QA-01` -> `done` when smoke and baseline artifacts pass
9. `FND-01` and `FND-02` -> `done` after QA pass

## Blocker Protocol

Raise a blocker immediately if:

- a builder needs to edit files inside the other builder's active write scope
- model names or field names drift from the locked contracts
- the app cannot run for shell-level smoke tests
- route design and Firestore rules no longer match

When blocked, the orchestrator should:

1. post a short user update
2. identify the blocking ticket IDs
3. decide whether the blocker is contract, integration, or implementation owned
4. redirect the owning builder with a precise correction

Suggested blocker update:

```text
FND-02 is blocked on a contract mismatch with FND-01 around route guard inputs. I'm resolving the contract at the orchestrator layer before builder-b continues.
```

## User Update Templates

### Ticket start

```text
FND-01 is in progress with builder-a on data access, roles, and score submission foundations. FND-02 will start once the route and model contracts are locked for builder-b.
```

### Parallel build start

```text
FND-01 and FND-02 are both running now. Builder-a owns models, rules, and repository changes; builder-b owns routing, guards, and shell surfaces.
```

### QA start

```text
QA-01 is starting. The shell routes are integrated and the QA agent is validating route reachability, role gating, and baseline desktop/mobile screenshots.
```

### QA failure

```text
QA-01 found a failure on FND-02: the public slug shell is not independently reachable. I'm routing that back to builder-b with the repro details.
```

### Milestone complete

```text
Milestone 1 is complete. The execution board, role contracts, route shells, and baseline QA harness are all in place, and the next wave can move into assistant operational flow.
```

## Definition of Done for `ORCH-01`

`ORCH-01` is done only when all of the following are true:

- the execution board exists and is usable as a live tracking artifact
- write scopes are explicitly separated for builder-a and builder-b
- stable contracts are documented
- handoff templates are ready
- milestone kickoff messaging is ready
- blocker protocol is defined
- QA handoff is prewritten

## Next Action After This Runbook

Once this runbook is in place, the next operational step is:

- activate `ORCH-01`
- hand off `FND-01` to builder-a
- hand off `FND-02` to builder-b using the locked contracts in the execution board

Do not start `QA-01` until the shell routes are integrated and runnable.
