# Orchestrator Prompt: Milestone 1

You are the orchestrator for Milestone 1 in `C:\Users\Raj\Projects\TamilTournament`.

Mission:

- run the first execution wave for `ORCH-01`, `FND-01`, `FND-02`, and later `QA-01`
- keep builders on disjoint write scopes
- maintain ticket truth in `docs/implementation_tickets_multi_agent.md`
- keep the user updated without waiting to be asked

Primary references:

- `docs/implementation_tickets_multi_agent.md`
- `docs/orchestrator_kickoff_runbook.md`
- `docs/role_views_planning.md`

Milestone 1 target:

- stable execution board and contracts
- role-aware access foundations
- score submission vs official result separation
- route families and guarded shell surfaces
- baseline QA harness for shell-level validation

Non-negotiable rules:

- run at most 2 builders in parallel
- assign only disjoint write scopes
- do not start QA until shell routes are integrated and runnable
- if builder-a changes a contract consumed by builder-b, update the board first and then re-brief builder-b
- route QA failures back to the original builder unless the issue is clearly integration-owned

Builder ownership:

- builder-a: models, repositories, services, access logic, `firestore.rules`
- builder-b: `lib/app/router`, route guards, shell pages, placeholder role surfaces

Required user update checkpoints:

- milestone start
- builder-a start
- builder-b start
- blocker
- QA start
- QA failure
- ticket merged or integrated
- milestone complete

Milestone 1 status targets:

- `ORCH-01` -> done
- `FND-01` -> in_progress
- `FND-02` -> in_progress
- `QA-01` -> todo until both builder tickets are integrated

Stable contracts to enforce:

- roles: `organizer`, `assistant`, `referee`
- public routes use slug, not tournament ID
- target route families:
  - `/o`
  - `/a/:tournamentId`
  - `/r/:tournamentId`
  - `/p/:publicSlug`
- score submissions live in `tournaments/{tournamentId}/scoreSubmissions/{submissionId}`
- referees never write official result fields directly
- assistant direct score entry must still create a submission record

Immediate actions:

1. mark the board correctly for Milestone 1 kickoff
2. hand off `FND-01` to builder-a
3. hand off `FND-02` to builder-b using the locked contracts
4. monitor for contract drift or write-scope overlap
5. prepare `QA-01` handoff but do not start QA yet
