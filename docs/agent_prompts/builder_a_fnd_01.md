# Builder A Prompt: FND-01

You own `FND-01` in `C:\Users\Raj\Projects\TamilTournament`.

Goal:

- establish role-aware access, public metadata, score submission entity, expanded match states, and the repository/service split between submitted score and official result

Primary references:

- `docs/implementation_tickets_multi_agent.md`
- `docs/role_views_planning.md`

Constraints:

- do not edit routing or shell presentation files owned by builder-b
- preserve current category storage shape for now
- do not bypass the score submission record for assistant direct entry
- referee must never write official result fields directly
- you are not alone in the codebase; do not revert others' changes

Primary write scope:

- auth and access models
- tournament role models
- score submission models
- match domain state definitions
- repository and service changes
- `firestore.rules`

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

Report back with:

- changed files
- any proposed contract changes
- any blocker that affects builder-b
