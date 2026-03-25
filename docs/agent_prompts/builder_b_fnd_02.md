# Builder B Prompt: FND-02

You own `FND-02` in `C:\Users\Raj\Projects\TamilTournament`.

Goal:

- create route families and guarded shell surfaces for organizer, assistant, referee, and public player access

Primary references:

- `docs/implementation_tickets_multi_agent.md`
- `docs/orchestrator_kickoff_runbook.md`

Locked contracts:

- roles: `organizer`, `assistant`, `referee`
- public routes use tournament slug
- target route families:
  - `/o`
  - `/a/:tournamentId`
  - `/r/:tournamentId`
  - `/p/:publicSlug`
- shell work only for this ticket; do not implement deep feature flows yet

Constraints:

- do not edit `firestore.rules` or repository/service files owned by builder-a
- keep shell surfaces independent of unfinished feature internals
- public slug routes must not depend on organizer auth flow
- you are not alone in the codebase; do not revert others' changes

Primary write scope:

- `lib/app/router`
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

Report back with:

- changed files
- any route or guard assumptions
- any contract mismatch that blocks progress
