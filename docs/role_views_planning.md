# Referee, Assistant, and Player Views Planning

## Why This Planning Pass

The organizer workspace is already the strongest part of the product. The next expansion should not be treated as "more organizer tabs." It should be treated as three separate role-specific surfaces that sit on top of the same tournament data:

- referee view
- assistant view
- player/public view

This document captures the product decisions confirmed so far, the architectural implications for the current codebase, and the recommended implementation order.

## Confirmed Product Decisions

### Assistant

Assistants should be able to:

- queue matches onto courts
- manage operational court flow
- submit scores
- approve and commit scores

This makes the assistant role an operational floor role, not just a passive helper role.

### Referee

Referees should be able to:

- find the current match
- submit scores
- add notes if needed

Referees should not be able to:

- commit scores
- make results official
- adjust court assignments
- modify tournament structure

Assistant or organizer approval is required before a referee-submitted score becomes official.

### Player View

Player view can be fully public in v1.

That means:

- no authentication required for player-facing pages
- pages should be shareable by link
- public screens should only show official approved tournament state

## What The Current Codebase Looks Like

The current implementation is organizer-first and organizer-only:

- auth currently resolves to organizer dashboard or sign-in in `lib/features/auth/presentation/auth_gate.dart`
- routes only include `/` and `/tournaments/:tournamentId` in `lib/app/router/app_router.dart`
- Firestore rules only allow organizer access in `firestore.rules`
- match completion currently writes official results directly in `lib/features/scheduler/data/tournament_match_repository.dart`
- match status is currently simplified to `pending`, `ready`, `on_court`, and `completed` in `lib/features/scheduler/domain/tournament_match.dart`
- categories are stored in top-level collection `categories` in `lib/features/categories/data/category_repository.dart`
- entries, matches, and courts are stored under `tournaments/{tournamentId}/...`

This matters because the next views require:

- more roles than "organizer"
- partial write permissions
- public read models
- a separation between submitted score and official result

## Plain-English Note On The Category Storage Question

The "migrate categories" question is about where category documents live in Firestore.

Right now:

- categories live in top-level collection `categories`
- entries live in `tournaments/{id}/entries`
- matches live in `tournaments/{id}/matches`
- courts live in `tournaments/{id}/courts`

That split works for the organizer surface, but it becomes awkward once we add:

- public tournament pages
- role-based rules
- tournament-scoped membership
- tournament-scoped public publishing

Recommended long-term shape:

```text
tournaments/{tournamentId}/categories/{categoryId}
```

instead of:

```text
categories/{categoryId}
```

You do not need to migrate this immediately before starting the new views, but the team should choose one of these paths early:

1. Migrate categories into tournament subcollections before role/public work grows.
2. Keep the current storage temporarily, but hide it behind repositories and plan a migration later.

Recommended approach: do not block feature work on a migration, but stop leaking collection shape into UI and controller code now.

## Role Model Recommendation

Add tournament-scoped roles rather than continuing to rely only on:

- `organizerUid`
- `organizerEmails`

Recommended collection:

```text
tournaments/{tournamentId}/roles/{roleId}
```

Recommended fields:

- `userId`
- `email`
- `displayName`
- `role`
- `isActive`
- `assignedAt`
- `assignedBy`

Recommended v1 roles:

- `organizer`
- `assistant`
- `referee`

Public/player view does not need a role document in v1.

## Permission Model

### Organizer

- full tournament control
- manage setup, entries, categories, courts, scheduling
- approve or reject scores
- same or broader access than assistant

### Assistant

- read tournament operational data
- queue matches onto courts
- move matches through floor workflow if allowed by product rules
- submit scores
- approve and commit scores
- no access to tournament structure editing, seeding, or high-risk admin settings unless explicitly granted later

### Referee

- read match lookup data
- read currently assigned or current matches
- create score submissions
- optionally submit correction notes
- no direct writes to official match completion fields

### Public Player

- read-only access
- only official approved data
- no pending submissions
- no role data
- no audit data

## Product Surface Definition

### Assistant Surface

Primary purpose:

- run the floor
- keep courts moving
- approve and finalize results when appropriate

Likely screens:

- assistant home
- live court board
- match queue / ready list
- match detail
- score approval / commit flow

Key actions:

- assign ready match to a court
- move or unassign a match
- mark match called or on court if the product wants that extra state
- review referee score submission
- approve and commit score
- directly submit and commit score if assistant entered it

### Referee Surface

Primary purpose:

- fast, low-friction score capture from courtside

Likely screens:

- referee home
- find match by court or code
- submit score
- submission confirmation

Key actions:

- open active match
- enter best-of-3 game scores
- submit
- see pending/submitted state

### Player/Public Surface

Primary purpose:

- reduce interruptions to staff
- answer "where do I play", "what happened", and "what is next"

Likely screens:

- public tournament home
- category list
- category detail
- live courts board
- results feed
- search
- pair detail

Key actions:

- view official standings
- view current and upcoming court assignments
- search by player or pair
- follow one category or pair

## Core Data Model Changes

### 1. Role Membership

Add tournament role documents for assistant and referee access.

### 2. Public Publishing Fields

Recommended tournament fields:

- `publicSlug`
- `isPublic`
- `publicStatus`

Recommended category field:

- `isPublished`

### 3. Match State Expansion

Current match status is too small for the next workflow.

Recommended operational states:

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

Not all of these need to ship on day one, but the model should be prepared for them.

### 4. Score Submission Entity

Add:

```text
tournaments/{tournamentId}/scoreSubmissions/{submissionId}
```

Recommended fields:

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

Recommended states:

- `pending`
- `approved`
- `rejected`

### 5. Match Approval Metadata

Match documents should gain explicit official-result metadata rather than assuming any saved score is official.

Recommended fields:

- `officialScoreSubmissionId`
- `officializedByUserId`
- `officializedByRole`
- `officializedAt`

### 6. Optional Assignment Fields

Recommended optional fields if useful operationally:

- `assignedRefereeUserId`
- `assignedAssistantUserId`
- `calledAt`
- `actualStartAt`
- `actualEndAt`

## Workflow Design

### Workflow A: Assistant Queues a Match

1. Assistant opens live queue.
2. Assistant selects a ready match.
3. Assistant assigns it to an available court.
4. Match status moves to `assigned` or `called`.
5. Public court board updates.

### Workflow B: Referee Submits Score

1. Referee finds match by court or code.
2. Referee enters best-of-3 score.
3. App validates score shape.
4. Score submission is created with `pending` status.
5. Match status becomes `score_submitted` if appropriate.
6. Result is not yet official.

### Workflow C: Assistant Approves Referee Score

1. Assistant opens pending submissions.
2. Assistant reviews submitted score.
3. Assistant approves or rejects.
4. On approval:
   - match becomes `completed`
   - official game scores are written to match
   - winner fields are written
   - standings recalculate
   - dependent knockout matches can unlock

### Workflow D: Assistant Direct Entry

1. Assistant opens match detail.
2. Assistant enters score directly.
3. App can create a submission and auto-approve it in one action, or use a direct commit path with audit metadata.

Recommended approach:

- keep one submission pipeline
- assistant direct entry should still create a submission record
- assistant approval can happen in the same transaction or service operation

This keeps the audit trail simple.

### Workflow E: Organizer Override

1. Organizer opens a completed or pending match.
2. Organizer can approve, reject, or correct.
3. Corrections are logged as new submissions or audit entries rather than silent overwrites.

### Workflow F: Public Player Visibility

1. Public user opens tournament slug page.
2. They view categories, courts, results, and search.
3. They only see official approved data.
4. Pending submissions and private notes remain hidden.

## Route Plan

Recommended route families:

```text
/o
/o/tournaments/:tournamentId

/a/:tournamentId
/a/:tournamentId/courts
/a/:tournamentId/matches/:matchId
/a/:tournamentId/scores

/r/:tournamentId
/r/:tournamentId/matches/:matchId

/p/:publicSlug
/p/:publicSlug/categories
/p/:publicSlug/categories/:categoryId
/p/:publicSlug/courts
/p/:publicSlug/results
/p/:publicSlug/search
/p/:publicSlug/pairs/:entryId
```

Alternative:

- use slug for all public routes
- keep authenticated roles on `tournamentId`

That is the cleaner split for now.

## UI Direction

### Assistant UI

- mobile-first but comfortable on tablet
- operational density matters more than visual flourish
- emphasis on court status, queue position, and fast actions

### Referee UI

- phone-first
- large numeric score controls
- very few decisions per screen
- strong confirmation states

### Player UI

- public web-first with mobile priority
- easy scanning
- quick answer surfaces:
  - current court board
  - next matches
  - results
  - search

## Firestore Security Plan

### Authenticated rules

Add helper functions that resolve tournament role membership.

Examples of needs:

- organizer can read/write all tournament internals
- assistant can read tournament operational data, write allowed match and score actions
- referee can read match lookup data and create score submissions

### Public rules

Public access should be allowed only for explicitly public tournaments and only on safe fields/collections.

There are two common approaches:

1. Let public clients read selected tournament collections directly.
2. Create public read-model collections that only contain safe approved data.

Recommended approach for v1:

- start with direct reads if the data shape is simple
- move to dedicated public read models if rules or query shape becomes fragile

## Service Layer Changes

The current `TournamentMatchRepository` mixes operational updates and official result writes. That should be split.

Recommended new services:

- `RoleAccessService`
- `MatchAssignmentService`
- `ScoreSubmissionService`
- `ScoreApprovalService`
- `PublicTournamentQueryService`

Recommended responsibilities:

### MatchAssignmentService

- validate assistant assignment actions
- assign/unassign court
- move between ready, assigned, called, on-court states

### ScoreSubmissionService

- validate game score shape
- create pending submission
- attach submission metadata to match

### ScoreApprovalService

- approve or reject submission
- write official match result
- recalculate standings
- unlock dependent knockout matches

## Build Order

### Phase 1: Foundation

- add tournament role model
- add public slug and publish fields
- add score submission model
- extend match statuses
- refactor repositories so official score commit is separate from score submission

### Phase 2: Assistant Surface

- assistant route shell
- live queue and court board
- assign-to-court actions
- assistant score entry and commit
- organizer and assistant approval inbox

This should come first because it has the highest event-day leverage.

### Phase 3: Referee Surface

- referee match lookup
- score entry flow
- pending submission confirmation
- handoff into assistant/organizer approval

### Phase 4: Player/Public Surface

- public home
- category detail
- courts board
- results feed
- search and pair detail

### Phase 5: Polish and Hardening

- QR links by court or match
- stricter audit trail
- better correction flows
- performance tuning for public pages

## Recommended Near-Term Decisions

These should be locked before implementation starts:

### 1. Assistant Scope

Confirmed:

- assistants can queue matches
- assistants can submit and commit scores

Still to decide:

- can assistants reorder ready queue globally
- can assistants mark forfeit
- can assistants move knockout placeholders

### 2. Referee Scope

Confirmed:

- referees submit only

Still to decide:

- can referees see only assigned matches, or all current on-court matches
- can referees submit corrections after a rejection

### 3. Public Scope

Confirmed:

- fully public

Still to decide:

- whether search is by pair name only or also by player name
- whether category pages show upcoming unofficial placeholders or only resolved official pairings

## Acceptance Criteria For The First Milestone

The first milestone should be considered successful if:

- assistants can assign ready matches to courts
- referees can submit scores without gaining organizer-level access
- assistant or organizer approval is required before referee scores become official
- assistants can directly enter and commit scores through the same audit-safe pipeline
- public pages show official standings, courts, and results without exposing internal operational data

## Recommendation

Start with the assistant and referee workflow before building the public player surface.

Reason:

- it forces the right role model
- it forces the score approval pipeline
- it removes the current direct organizer-only scoring assumption
- it creates the clean official-state boundary that the public player pages need

Once that boundary exists, public pages become much safer and easier to build.
