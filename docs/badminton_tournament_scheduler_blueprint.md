
# Badminton Tournament Scheduler App Blueprint

## Application Overview

This application is a **Flutter-based badminton tournament operations platform** designed to help organizers run live doubles tournaments with speed, clarity, and fewer manual errors. It is built around the real operational flow of local and regional badminton events where registrations arrive through Google Forms, organizers manually approve entries, multiple divisions run in parallel, referees submit official scores, and the scheduling team must constantly adapt to changing court availability and player overlap across categories.

The first production target for the app is a **badminton tournament weekend MVP**, but the foundation is designed so the product can grow into a broader tournament platform later. The current scope is intentionally optimized for **doubles badminton**, with categories such as **40+**, **50+**, **Men’s Open**, and **Women’s Open**, and with a tournament structure that automatically adapts based on the number of approved entries in each category.

At its core, the application is not just a bracket generator. It is a **live tournament control system**. It will manage the tournament from registration intake to check-in, category formation, seeding, group generation, round-robin scheduling, semifinal and final qualification, rolling court assignment, referee score submission, organizer approval, public standings, printable operational sheets, and live audience visibility.

The app will support several distinct user experiences:

- **Organizer/Admin**: full control over tournament configuration, entries, categories, court status, match scheduling, score approval, and print outputs.
- **Scheduler/Helper**: event-day operational access to assign matches, react to delays, manage check-in, and keep the event moving.
- **Referee/Score Submitter**: a lightweight workflow to submit official match scores for organizer approval.
- **Player/Public Viewer**: a read-only interface for participants and spectators to view standings, court assignments, upcoming matches, completed results, and category progression.

The app will be built using:

- **Flutter** for mobile, tablet, and web UI
- **Google Cloud Firestore** as the real-time database
- **Google Authentication** for login and role-based access
- **Google Cloud Storage** for generated files, exports, and optional tournament assets

The system will rely heavily on **Firestore real-time listeners** so that operational screens, public standings, court boards, and score approval queues update automatically without requiring a full notification system in the first version.

---

## Product Goals

### Primary Goal
Make it possible for a small organizer team to run a multi-category badminton tournament across multiple courts with less confusion, fewer scheduling conflicts, and much better visibility for participants.

### Secondary Goals
- Reduce repeated participant questions like “When is our next match?” and “Which court are we on?”
- Prevent accidental scheduling conflicts when a player appears in more than one category
- Support event-day disruptions such as a temporary court outage
- Provide strong print support for court sheets, division sheets, check-in sheets, and running order
- Create a strong base for future tournament formats and future sports

### Non-Goals for Initial Version
- Full payment processing
- Advanced player ranking system
- Push notifications
- Rich social/player profile features
- AI auto-optimization of the entire event
- Offline-first conflict resolution

---

## Tournament Rules and Assumptions

The following business rules are assumed for the first badminton version:

### Registration Model
- Registration is **pair-based**
- Each entry is one **doubles pair**
- Registration data usually comes from a **Google Form**
- Typical fields:
  - category
  - pair name or display name
  - captain name
  - player 1 name
  - player 2 name
  - age
  - contact details
  - payment note or status if needed
- Entries are **approved manually**
- Waitlists are supported
- Withdrawal is allowed until tournament policy cutoff
- Age is **organizer-trusted**
- Payment tracking is lightweight in MVP

### Category Model
- Categories are configured per tournament
- Current expected categories:
  - 40+
  - 50+
  - Men’s Open
  - Women’s Open
- All categories are **doubles only**

### Cross-Category Participation
- A player may not appear more than once in the **same category**
- A player may appear in **different categories**
- Example: one player may be in **40+** and **Men’s Open**
- Scheduler should detect and avoid **overlapping match assignments** for such players

### Match Rules
- Best of 3 games
- Each game to 21 points
- Scores are captured per game
- Referee submits official score
- Organizer approves score before the result becomes official

### Format Rules by Category Size
- **7 or fewer entries**:
  - single round robin
  - top 4 advance to semifinals
  - semifinal 1 = rank 1 vs rank 4
  - semifinal 2 = rank 2 vs rank 3
  - winners advance to final
- **8 or more entries**:
  - split entries into Group A and Group B
  - round robin within each group
  - top 2 from each group advance to semifinals
  - semifinal 1 = A1 vs B2
  - semifinal 2 = B1 vs A2
  - winners advance to final

### Seeding Rules
- Seeding is generated automatically by the app
- Organizer can edit seed order and group composition if there is imbalance
- Default group formation uses **snake seeding**

### Court Rules
- Facility may have more courts physically available than are used productively
- Scheduler plans around **10 active courts**
- All courts are interchangeable
- Courts may become temporarily unavailable and later return
- Court-specific features are not required in MVP

### Match Readiness Rules
- If a pair is not ready, decision is **manual**
- No minimum rest gap is required
- Scheduler only blocks actual match overlap, not short turnaround

---

## High-Level Capabilities

The application will support the following major capabilities.

### 1. Tournament Setup
- Create tournament
- Set venue, date, time, categories
- Set productive court count
- Assign organizers and helpers
- Configure tournament rule set

### 2. Registration Intake
- Import registration data from Google Forms export or CSV
- Normalize player names
- Create entries
- Approve, waitlist, withdraw, or edit entries
- Track check-in

### 3. Category Formation
- Apply automatic format rules based on number of approved entries
- Generate round robin schedule or A/B groups
- Generate semifinal and final placeholders
- Support organizer edits before play begins

### 4. Seeding and Grouping
- Assign automatic seeds
- Allow organizer to adjust seeds
- Auto-create groups for 8+ entries
- Allow organizer to manually swap entries between groups if needed

### 5. Live Scheduling
- Show ready queue of matches
- Assign matches to courts on a rolling basis
- Block player overlap across categories
- React to temporary court outages
- Support held, delayed, called, in-progress, and forfeit states

### 6. Score Submission and Approval
- Referee or helper submits official score
- Organizer reviews and approves
- Approved scores update standings, qualification, and final progression
- Rejected scores go back for correction

### 7. Public Visibility
- Live standings
- Current court assignments
- Upcoming matches
- Completed results
- Search by player or pair

### 8. Print and Export
- Court sheets
- Division sheets
- Running order
- Check-in sheets
- Optional PDF export via server or client print pipeline

### 9. Auditability
- Track major operational changes
- Store who approved results and who changed key objects

---

## Delivery Stages

### Stage 1 - Core Tournament Admin Foundation
This stage establishes the foundational infrastructure.

#### Includes
- Firebase project setup
- Google Auth
- role-based routing
- Firestore schema
- tournament creation
- category setup
- entry import and management
- player normalization
- check-in status
- court configuration

#### Outcome
The organizer can create a tournament, import entries, manage categories, and prepare the event structure.

---

### Stage 2 - Category Engine and Match Generation
This stage implements tournament logic.

#### Includes
- automatic seeding
- editable seeding
- round robin generation for 7 or fewer entries
- group generation for 8 or more entries
- semifinal/final placeholder generation
- standings engine
- qualification engine

#### Outcome
Each category can be generated fully and tracked correctly through semifinals and final.

---

### Stage 3 - Live Scheduler and Court Control
This is the operational heart of the application.

#### Includes
- ready queue
- rolling court assignment
- court status board
- temporary court unavailable / available toggle
- player conflict detection across categories
- match state transitions
- manual hold / delay / forfeit actions

#### Outcome
Organizers can run the tournament live from the scheduler without relying on spreadsheets or WhatsApp for core logistics.

---

### Stage 4 - Referee Submission and Score Approval
This stage closes the loop on official results.

#### Includes
- referee score submit view
- score validation
- organizer approval workflow
- standings and bracket update after approval
- score correction flow

#### Outcome
Official results flow into the system cleanly and safely.

---

### Stage 5 - Public View and Search
This stage improves participant and audience visibility.

#### Includes
- public category pages
- public standings
- live court board
- upcoming matches
- completed results
- search by player or pair

#### Outcome
Participants can self-serve most of the information they need.

---

### Stage 6 - Print, Exports, and Operational Polish
This stage supports real-world event-day usage.

#### Includes
- printable court sheets
- printable division sheets
- printable running order
- printable check-in sheets
- audit screen
- operational history
- optional QR links to public pages

#### Outcome
The app becomes a complete event operations platform.

---

## Architecture Overview

### Frontend
- Flutter
- Material 3
- responsive layout for mobile, tablet, and web
- role-aware navigation
- modular feature architecture

### Backend
- Firebase Authentication for identity
- Firestore for real-time structured operational data
- Cloud Storage for generated documents and assets
- Optional Cloud Functions for:
  - generation jobs
  - standings recalculation
  - printable file generation
  - integrity checks
  - audit logging

### Real-Time Behavior
Firestore listeners power:
- court board live updates
- score approval queue
- standings
- running order
- public category pages

### Recommended Flutter Structure
Feature-first foldering:
- auth
- tournaments
- entries
- categories
- scheduler
- courts
- scores
- public_view
- print_exports
- shared

Use:
- Riverpod or Bloc for state management
- strongly typed Firestore repositories
- DTO/domain model separation
- route guards by role

---

## Entity Model

Below is the recommended entity model for the badminton tournament app.

### 1. User
Represents a signed-in person using Google Auth.

#### Purpose
Identity and role assignment.

#### Key fields
- userId
- email
- displayName
- photoUrl
- isActive
- createdAt
- lastLoginAt

---

### 2. Tournament
Represents one tournament event.

#### Purpose
Top-level container for everything in the event.

#### Key fields
- tournamentId
- name
- venueName
- address
- startDate
- endDate
- status
- activeCourtCount
- timezone
- publicSlug
- createdBy
- createdAt
- updatedAt

---

### 3. TournamentRole
Maps users into tournament-specific roles.

#### Purpose
Allows multiple organizers, helpers, schedulers, and admins per tournament.

#### Key fields
- tournamentRoleId
- tournamentId
- userId
- role
- isActive
- assignedAt
- assignedBy

#### Roles
- admin
- organizer
- scheduler
- helper
- referee_submitter
- public_viewer

---

### 4. Category
Represents a division within a tournament.

#### Purpose
Defines the competitive grouping such as Men’s Open or 40+.

#### Key fields
- categoryId
- tournamentId
- name
- genderType
- ageRuleLabel
- formatType
- status
- displayOrder
- entryCount
- groupMode
- isLocked
- createdAt
- updatedAt

#### Example values
- name: Men’s Open
- formatType:
  - rr_top4
  - groups_top2
- status:
  - draft
  - generated
  - in_progress
  - completed

---

### 5. Player
Represents a person participating in one or more entries across categories.

#### Purpose
Needed for cross-category conflict detection and better search.

#### Key fields
- playerId
- normalizedName
- displayName
- age
- gender
- contactPhone
- notes
- createdAt
- updatedAt

---

### 6. Entry
Represents one doubles pair in one category.

#### Purpose
Core competitive registration object.

#### Key fields
- entryId
- tournamentId
- categoryId
- pairDisplayName
- captainName
- captainPhone
- player1Id
- player2Id
- player1NameSnapshot
- player2NameSnapshot
- seedNumber
- registrationSource
- approvalStatus
- waitlistPosition
- checkInStatus
- checkInTime
- withdrawReason
- notes
- createdAt
- updatedAt

#### approvalStatus values
- pending
- approved
- waitlisted
- withdrawn
- rejected

#### checkInStatus values
- not_checked_in
- checked_in
- late
- absent

---

### 7. Court
Represents a court in the venue.

#### Purpose
Operational scheduling resource.

#### Key fields
- courtId
- tournamentId
- code
- name
- displayOrder
- status
- unavailableReason
- lastStatusChangedAt
- updatedAt

#### status values
- available
- occupied
- temporarily_unavailable

---

### 8. Match
Represents one playable competitive match.

#### Purpose
Drives scheduling, scoring, standings, and progression.

#### Key fields
- matchId
- tournamentId
- categoryId
- stageType
- stageLabel
- groupCode
- roundNumber
- sequenceNumber
- entryAId
- entryBId
- entryANameSnapshot
- entryBNameSnapshot
- dependsOnMatchIds
- winnerEntryId
- loserEntryId
- status
- assignedCourtId
- plannedStartAt
- actualStartAt
- actualEndAt
- estimatedDurationMinutes
- calledAt
- holdReason
- forfeitWinnerEntryId
- createdAt
- updatedAt

#### stageType values
- round_robin
- group_stage
- semifinal
- final

#### status values
- pending
- ready
- assigned
- called
- in_progress
- score_submitted
- completed
- manual_hold
- delayed
- forfeit
- cancelled

---

### 9. MatchGameScore
Represents the score of one game within a match.

#### Purpose
Stores best-of-3 game details.

#### Key fields
- matchGameScoreId
- tournamentId
- matchId
- gameNumber
- entryAPoints
- entryBPoints
- winnerEntryId
- createdAt
- updatedAt

---

### 10. ScoreSubmission
Represents a submitted official result awaiting approval or already approved.

#### Purpose
Separate operational score submission from final official match result.

#### Key fields
- scoreSubmissionId
- tournamentId
- matchId
- submittedByUserId
- submittedByRole
- submissionMethod
- proposedWinnerEntryId
- game1EntryAPoints
- game1EntryBPoints
- game2EntryAPoints
- game2EntryBPoints
- game3EntryAPoints
- game3EntryBPoints
- note
- approvalStatus
- approvedByUserId
- approvedAt
- rejectedReason
- createdAt
- updatedAt

#### approvalStatus values
- pending
- approved
- rejected

---

### 11. StandingsSnapshot
Represents computed standings at a point in time.

#### Purpose
Fast display of standings and tiebreakers without recomputing in every client.

#### Key fields
- standingsSnapshotId
- tournamentId
- categoryId
- groupCode
- entryId
- rank
- matchesPlayed
- matchesWon
- matchesLost
- gamesWon
- gamesLost
- gameDifferential
- pointsWon
- pointsLost
- pointDifferential
- qualifiedStatus
- tieBreakNotes
- computedAt

#### qualifiedStatus values
- not_qualified
- semifinal_qualified
- finalist
- champion

---

### 12. RunningOrderItem
Represents an operational queue item for display and printing.

#### Purpose
Master running order and sequencing support.

#### Key fields
- runningOrderItemId
- tournamentId
- matchId
- categoryId
- orderIndex
- assignedCourtId
- status
- note
- createdAt
- updatedAt

---

### 13. CourtAssignmentHistory
Represents assignment changes over time.

#### Purpose
Audit court movements and operational shifts.

#### Key fields
- courtAssignmentHistoryId
- tournamentId
- matchId
- fromCourtId
- toCourtId
- changedByUserId
- reason
- changedAt

---

### 14. CheckInEvent
Represents a check-in activity.

#### Purpose
Provides traceability for event-day check-in actions.

#### Key fields
- checkInEventId
- tournamentId
- entryId
- statusBefore
- statusAfter
- changedByUserId
- note
- changedAt

---

### 15. AuditLog
Represents meaningful system changes.

#### Purpose
Event trace for corrections and accountability.

#### Key fields
- auditLogId
- tournamentId
- entityType
- entityId
- action
- beforeJson
- afterJson
- performedByUserId
- performedAt

---

### 16. DocumentAsset
Represents generated or uploaded assets.

#### Purpose
Track exported files and future tournament media.

#### Key fields
- documentAssetId
- tournamentId
- type
- storagePath
- fileName
- contentType
- generatedByUserId
- createdAt

#### type values
- court_sheet
- division_sheet
- running_order
- check_in_sheet
- logo
- public_banner

---

## Firestore Collection Design

Firestore is document-oriented, so the data model should be optimized for read-heavy tournament-day usage.

### Recommended top-level collections

- `users`
- `tournaments`

### Recommended nested collections under each tournament
- `tournaments/{tournamentId}/roles`
- `tournaments/{tournamentId}/categories`
- `tournaments/{tournamentId}/players`
- `tournaments/{tournamentId}/entries`
- `tournaments/{tournamentId}/courts`
- `tournaments/{tournamentId}/matches`
- `tournaments/{tournamentId}/scoreSubmissions`
- `tournaments/{tournamentId}/standings`
- `tournaments/{tournamentId}/runningOrder`
- `tournaments/{tournamentId}/courtAssignmentHistory`
- `tournaments/{tournamentId}/checkInEvents`
- `tournaments/{tournamentId}/auditLogs`
- `tournaments/{tournamentId}/documentAssets`

### Example structure

```text
users/{userId}
tournaments/{tournamentId}
tournaments/{tournamentId}/roles/{roleId}
tournaments/{tournamentId}/categories/{categoryId}
tournaments/{tournamentId}/players/{playerId}
tournaments/{tournamentId}/entries/{entryId}
tournaments/{tournamentId}/courts/{courtId}
tournaments/{tournamentId}/matches/{matchId}
tournaments/{tournamentId}/scoreSubmissions/{scoreSubmissionId}
tournaments/{tournamentId}/standings/{standingsSnapshotId}
tournaments/{tournamentId}/runningOrder/{runningOrderItemId}
tournaments/{tournamentId}/courtAssignmentHistory/{historyId}
tournaments/{tournamentId}/checkInEvents/{checkInEventId}
tournaments/{tournamentId}/auditLogs/{auditLogId}
tournaments/{tournamentId}/documentAssets/{documentAssetId}
```

---

## Firestore “Table” Definitions

The following section expresses the Firestore collections in a table-like schema format for implementation planning.

### users

| Field | Type | Required | Notes |
|---|---|---:|---|
| userId | string | yes | Firebase Auth UID |
| email | string | yes | login email |
| displayName | string | no | user display name |
| photoUrl | string | no | Google profile image |
| isActive | bool | yes | active flag |
| createdAt | timestamp | yes | created time |
| lastLoginAt | timestamp | no | last login |

### tournaments

| Field | Type | Required | Notes |
|---|---|---:|---|
| tournamentId | string | yes | document id |
| name | string | yes | tournament name |
| venueName | string | yes | venue |
| address | string | no | address |
| startDate | timestamp | yes | start |
| endDate | timestamp | no | end |
| status | string | yes | draft / active / completed |
| activeCourtCount | number | yes | productive court count |
| timezone | string | yes | e.g. America/Chicago |
| publicSlug | string | no | public routing slug |
| createdBy | string | yes | user id |
| createdAt | timestamp | yes | created |
| updatedAt | timestamp | yes | updated |

### tournament roles

| Field | Type | Required | Notes |
|---|---|---:|---|
| tournamentRoleId | string | yes | document id |
| tournamentId | string | yes | parent ref snapshot |
| userId | string | yes | linked user |
| role | string | yes | admin / organizer / scheduler / helper / referee_submitter |
| isActive | bool | yes | active flag |
| assignedAt | timestamp | yes | assigned time |
| assignedBy | string | no | user id |

### categories

| Field | Type | Required | Notes |
|---|---|---:|---|
| categoryId | string | yes | document id |
| tournamentId | string | yes | parent ref snapshot |
| name | string | yes | category name |
| genderType | string | no | men / women / mixed / open |
| ageRuleLabel | string | no | 40+ / 50+ |
| formatType | string | yes | rr_top4 / groups_top2 |
| status | string | yes | draft / generated / in_progress / completed |
| displayOrder | number | yes | UI order |
| entryCount | number | yes | denormalized |
| groupMode | string | no | none / A_B |
| isLocked | bool | yes | prevent unsafe regen |
| createdAt | timestamp | yes | created |
| updatedAt | timestamp | yes | updated |

### players

| Field | Type | Required | Notes |
|---|---|---:|---|
| playerId | string | yes | document id |
| normalizedName | string | yes | uppercase normalized name |
| displayName | string | yes | original display |
| age | number | no | trusted organizer value |
| gender | string | no | optional |
| contactPhone | string | no | optional |
| notes | string | no | optional |
| createdAt | timestamp | yes | created |
| updatedAt | timestamp | yes | updated |

### entries

| Field | Type | Required | Notes |
|---|---|---:|---|
| entryId | string | yes | document id |
| tournamentId | string | yes | parent ref snapshot |
| categoryId | string | yes | category |
| pairDisplayName | string | yes | pair or display name |
| captainName | string | no | captain |
| captainPhone | string | no | phone |
| player1Id | string | yes | linked player |
| player2Id | string | yes | linked player |
| player1NameSnapshot | string | yes | display copy |
| player2NameSnapshot | string | yes | display copy |
| seedNumber | number | no | ranking order |
| registrationSource | string | no | google_form / manual / csv |
| approvalStatus | string | yes | pending / approved / waitlisted / withdrawn / rejected |
| waitlistPosition | number | no | if waitlisted |
| checkInStatus | string | yes | not_checked_in / checked_in / late / absent |
| checkInTime | timestamp | no | check-in time |
| withdrawReason | string | no | reason |
| notes | string | no | misc |
| createdAt | timestamp | yes | created |
| updatedAt | timestamp | yes | updated |

### courts

| Field | Type | Required | Notes |
|---|---|---:|---|
| courtId | string | yes | document id |
| tournamentId | string | yes | parent ref snapshot |
| code | string | yes | e.g. C1 |
| name | string | yes | Court 1 |
| displayOrder | number | yes | visible order |
| status | string | yes | available / occupied / temporarily_unavailable |
| unavailableReason | string | no | optional |
| lastStatusChangedAt | timestamp | no | track operational change |
| updatedAt | timestamp | yes | updated |

### matches

| Field | Type | Required | Notes |
|---|---|---:|---|
| matchId | string | yes | document id |
| tournamentId | string | yes | parent ref snapshot |
| categoryId | string | yes | category |
| stageType | string | yes | round_robin / group_stage / semifinal / final |
| stageLabel | string | yes | display label |
| groupCode | string | no | A / B / null |
| roundNumber | number | no | round or grouping pass |
| sequenceNumber | number | no | display sequence |
| entryAId | string | no | becomes known later for dependent rounds |
| entryBId | string | no | becomes known later for dependent rounds |
| entryANameSnapshot | string | no | display copy |
| entryBNameSnapshot | string | no | display copy |
| dependsOnMatchIds | array<string> | no | semis/final dependencies |
| winnerEntryId | string | no | official winner |
| loserEntryId | string | no | official loser |
| status | string | yes | pending / ready / assigned / called / in_progress / score_submitted / completed / manual_hold / delayed / forfeit / cancelled |
| assignedCourtId | string | no | current court |
| plannedStartAt | timestamp | no | estimate |
| actualStartAt | timestamp | no | live start |
| actualEndAt | timestamp | no | live end |
| estimatedDurationMinutes | number | no | planning estimate |
| calledAt | timestamp | no | called time |
| holdReason | string | no | manual hold |
| forfeitWinnerEntryId | string | no | forfeit winner |
| createdAt | timestamp | yes | created |
| updatedAt | timestamp | yes | updated |

### match game scores

A dedicated subcollection can be used:

`tournaments/{tournamentId}/matches/{matchId}/games/{gameId}`

| Field | Type | Required | Notes |
|---|---|---:|---|
| matchGameScoreId | string | yes | document id |
| gameNumber | number | yes | 1 / 2 / 3 |
| entryAPoints | number | yes | score |
| entryBPoints | number | yes | score |
| winnerEntryId | string | no | winner of game |
| createdAt | timestamp | yes | created |
| updatedAt | timestamp | yes | updated |

### score submissions

| Field | Type | Required | Notes |
|---|---|---:|---|
| scoreSubmissionId | string | yes | document id |
| tournamentId | string | yes | parent ref snapshot |
| matchId | string | yes | linked match |
| submittedByUserId | string | no | referee/helper uid |
| submittedByRole | string | yes | role |
| submissionMethod | string | no | direct / qr / helper |
| proposedWinnerEntryId | string | yes | winner |
| game1EntryAPoints | number | yes | score |
| game1EntryBPoints | number | yes | score |
| game2EntryAPoints | number | yes | score |
| game2EntryBPoints | number | yes | score |
| game3EntryAPoints | number | no | optional |
| game3EntryBPoints | number | no | optional |
| note | string | no | comment |
| approvalStatus | string | yes | pending / approved / rejected |
| approvedByUserId | string | no | approver |
| approvedAt | timestamp | no | approval time |
| rejectedReason | string | no | reason |
| createdAt | timestamp | yes | created |
| updatedAt | timestamp | yes | updated |

### standings

| Field | Type | Required | Notes |
|---|---|---:|---|
| standingsSnapshotId | string | yes | document id |
| tournamentId | string | yes | parent ref snapshot |
| categoryId | string | yes | category |
| groupCode | string | no | A / B / null |
| entryId | string | yes | entry |
| rank | number | yes | current rank |
| matchesPlayed | number | yes | stats |
| matchesWon | number | yes | stats |
| matchesLost | number | yes | stats |
| gamesWon | number | yes | stats |
| gamesLost | number | yes | stats |
| gameDifferential | number | yes | tiebreaker |
| pointsWon | number | yes | tiebreaker |
| pointsLost | number | yes | tiebreaker |
| pointDifferential | number | yes | tiebreaker |
| qualifiedStatus | string | yes | not_qualified / semifinal_qualified / finalist / champion |
| tieBreakNotes | string | no | explanation |
| computedAt | timestamp | yes | recompute time |

### running order

| Field | Type | Required | Notes |
|---|---|---:|---|
| runningOrderItemId | string | yes | document id |
| tournamentId | string | yes | parent ref snapshot |
| matchId | string | yes | match |
| categoryId | string | yes | category |
| orderIndex | number | yes | display order |
| assignedCourtId | string | no | court |
| status | string | yes | pending / active / completed / held |
| note | string | no | operational note |
| createdAt | timestamp | yes | created |
| updatedAt | timestamp | yes | updated |

### audit logs

| Field | Type | Required | Notes |
|---|---|---:|---|
| auditLogId | string | yes | document id |
| tournamentId | string | yes | parent ref snapshot |
| entityType | string | yes | match / entry / category / court / scoreSubmission |
| entityId | string | yes | related entity |
| action | string | yes | create / update / approve / reject / move / hold |
| beforeJson | map | no | previous state |
| afterJson | map | no | new state |
| performedByUserId | string | no | actor |
| performedAt | timestamp | yes | time |

---

## Screen Map

This section defines every major screen and what each one reads and writes.

### Organizer/Admin Screens
1. Tournament Dashboard
2. Entries
3. Check-In
4. Categories Overview
5. Category Detail
6. Seeding
7. Scheduler Board
8. Match Detail
9. Courts
10. Scores Approval
11. Running Order
12. Print Center
13. Audit / History
14. Tournament Settings

### Referee/Helper Screens
15. Referee Home / Match Lookup
16. Submit Score
17. Submission Confirmation

### Public/Player Screens
18. Public Home
19. Category List
20. Category Detail Public
21. Live Courts Board
22. Results
23. Search
24. Pair Detail

---

## Screen to Entity Mapping

### 1. Tournament Dashboard

#### Purpose
Operational snapshot of tournament health.

#### Reads
- tournaments
- categories
- courts
- matches
- scoreSubmissions
- entries

#### Writes
- none directly, except navigation actions

#### Shows
- active matches
- courts available/unavailable
- check-in counts
- pending approvals
- category progress

---

### 2. Entries Screen

#### Purpose
Manage registration entries.

#### Reads
- entries
- players
- categories

#### Writes
- entries
- players
- auditLogs

#### Actions
- approve
- waitlist
- withdraw
- edit entry
- assign seed
- check-in
- move waitlist

---

### 3. Check-In Screen

#### Purpose
Fast event-day attendance management.

#### Reads
- entries
- categories

#### Writes
- entries
- checkInEvents
- auditLogs

#### Actions
- mark checked in
- mark late
- mark absent
- add note

---

### 4. Categories Overview

#### Purpose
See progress of all categories.

#### Reads
- categories
- entries
- matches
- standings

#### Writes
- none directly

---

### 5. Category Detail

#### Purpose
Manage one category’s structure and progression.

#### Reads
- category
- entries
- matches
- standings

#### Writes
- category
- matches
- standings
- auditLogs

#### Actions
- generate format
- regenerate before lock
- swap group members
- lock category
- override qualifier

---

### 6. Seeding Screen

#### Purpose
Order entries before generation.

#### Reads
- entries in category

#### Writes
- entries.seedNumber
- auditLogs

#### Actions
- auto-seed
- manual reorder
- clear seeds
- regenerate grouping

---

### 7. Scheduler Board

#### Purpose
Run the live event.

#### Reads
- matches
- courts
- entries
- players
- runningOrder
- categories
- scoreSubmissions

#### Writes
- matches
- courts
- runningOrder
- courtAssignmentHistory
- auditLogs

#### Actions
- assign match to court
- move match
- mark court unavailable
- free court
- hold match
- delay match
- mark in progress
- mark called
- mark forfeit

---

### 8. Match Detail

#### Purpose
Inspect and operate on a single match.

#### Reads
- match
- entry A
- entry B
- player documents
- score submissions
- games

#### Writes
- match
- games
- scoreSubmissions
- auditLogs

#### Actions
- update status
- change court
- approve score
- reject score
- edit result
- forfeit

---

### 9. Courts Screen

#### Purpose
Dedicated court management.

#### Reads
- courts
- matches
- runningOrder

#### Writes
- courts
- matches
- courtAssignmentHistory
- auditLogs

#### Actions
- mark court unavailable
- restore court
- clear future assignments
- move assignment

---

### 10. Scores Approval Screen

#### Purpose
Central inbox for official result approval.

#### Reads
- scoreSubmissions
- matches
- entries

#### Writes
- scoreSubmissions
- matches
- games
- standings
- auditLogs

#### Actions
- approve
- reject
- edit-and-approve
- open match detail

---

### 11. Running Order Screen

#### Purpose
Master operational sequence list.

#### Reads
- runningOrder
- matches
- categories
- courts

#### Writes
- runningOrder
- matches
- auditLogs

#### Actions
- reorder
- assign
- hold
- note
- print

---

### 12. Print Center

#### Purpose
Generate and download print-friendly artifacts.

#### Reads
- tournaments
- categories
- entries
- matches
- standings
- courts
- runningOrder

#### Writes
- documentAssets
- optional Cloud Storage output
- auditLogs

#### Outputs
- court sheets
- division sheets
- running order
- check-in sheets

---

### 13. Audit / History

#### Purpose
Operational traceability.

#### Reads
- auditLogs
- courtAssignmentHistory
- checkInEvents

#### Writes
- none directly

---

### 14. Tournament Settings

#### Purpose
Tournament configuration.

#### Reads
- tournament
- categories
- roles

#### Writes
- tournament
- categories
- roles
- auditLogs

#### Actions
- edit venue/date
- change active courts
- add/remove category
- assign organizer roles
- lock rules

---

### 15. Referee Home / Match Lookup

#### Purpose
Find the match to submit.

#### Reads
- matches
- courts

#### Writes
- none directly

#### Lookup methods
- by court
- by match code
- by assigned list
- later by QR

---

### 16. Submit Score

#### Purpose
Submit official referee result.

#### Reads
- match
- entries

#### Writes
- scoreSubmissions
- auditLogs

#### Actions
- submit score
- add note
- send correction

---

### 17. Submission Confirmation

#### Purpose
Show successful submission state.

#### Reads
- scoreSubmission
- match

#### Writes
- none

---

### 18. Public Home

#### Purpose
Top-level public view.

#### Reads
- tournament
- categories
- matches
- courts

#### Writes
- none

---

### 19. Category List

#### Purpose
List divisions.

#### Reads
- categories

#### Writes
- none

---

### 20. Category Detail Public

#### Purpose
Public standings and fixture visibility.

#### Reads
- category
- matches
- standings
- entries

#### Writes
- none

#### Important rule
Only shows approved official results, never pending score submissions.

---

### 21. Live Courts Board

#### Purpose
Show current and next court assignments.

#### Reads
- courts
- matches
- categories

#### Writes
- none

---

### 22. Results

#### Purpose
Upcoming, live, and completed result feed.

#### Reads
- matches
- categories
- courts

#### Writes
- none

---

### 23. Search

#### Purpose
Search by player or pair.

#### Reads
- players
- entries
- matches
- standings

#### Writes
- none

---

### 24. Pair Detail

#### Purpose
Show one pair’s position in the tournament.

#### Reads
- entry
- players
- matches
- standings

#### Writes
- none

---

## Operational Workflows

### Workflow 1 - Create Tournament
1. Admin signs in with Google Auth
2. Creates tournament
3. Sets venue/date/courts/categories
4. Invites organizers/helpers
5. Tournament enters draft state

### Workflow 2 - Import and Approve Entries
1. Organizer imports Google Form data
2. App normalizes player names and matches/reuses player records
3. Entries are created as pending
4. Organizer approves, waitlists, or withdraws entries
5. Entry count determines category format

### Workflow 3 - Seed and Generate Categories
1. App suggests seed order
2. Organizer adjusts if needed
3. For <= 7 entries, app creates full round robin
4. For >= 8 entries, app creates Group A and Group B using snake seeding
5. App creates semifinal and final placeholders
6. Category can be locked before play

### Workflow 4 - Check In
1. Organizer/helper opens check-in screen
2. Searches pair
3. Marks check-in state
4. Audit/check-in event is recorded

### Workflow 5 - Live Match Scheduling
1. Scheduler opens board
2. Ready matches appear
3. Scheduler assigns a match to an available court
4. System checks:
   - court availability
   - match readiness
   - player overlap across categories
5. Match becomes assigned/called/in-progress
6. Court status changes

### Workflow 6 - Court Outage
1. Court becomes unavailable
2. Scheduler marks court temporarily unavailable
3. Future assignments on that court are moved back to ready/held state
4. Scheduler reassigns affected matches elsewhere

### Workflow 7 - Score Submission and Approval
1. Referee/helper opens match
2. Submits best-of-3 score
3. ScoreSubmission is created in pending state
4. Organizer sees approval queue
5. Organizer approves or rejects
6. On approval:
   - Match becomes completed
   - Game scores are persisted
   - Standings recalculate
   - Dependent semifinal/final slots unlock if applicable

### Workflow 8 - Public Visibility
1. Public user opens public tournament page
2. Views standings, results, current courts
3. Searches by player or pair
4. Only official, approved data is visible

### Workflow 9 - Printing
1. Organizer opens Print Center
2. Chooses artifact type
3. App generates print layout or PDF
4. File stored in Cloud Storage and optionally downloaded

---

## Scheduler Rules

### Scheduling Philosophy
Use a **rolling scheduler**, not a rigid fixed-time-slot scheduler.

### Why
Badminton tournaments on live event day are dynamic. Courts free up unpredictably, player overlap matters, and manual intervention is necessary. A rolling scheduler fits the real-world organizer workflow far better.

### Hard Constraints
The scheduler must prevent:
- same player in overlapping matches
- same entry in overlapping matches
- same court assigned to overlapping matches
- scheduling a match before prerequisites are complete

### Soft Constraints
The scheduler should optionally prefer:
- earlier generated matches first
- balanced category progression
- minimizing idle semifinal/final delays

### Manual Overrides
Organizers may:
- hold a match
- delay a match
- assign manually
- declare forfeit
- override results
- rearrange groups before play begins

---

## Standings and Qualification Logic

### Default Tiebreaker Order
Assumed recommendation:
1. match wins
2. game differential
3. point differential
4. head-to-head
5. organizer override

### <= 7 Entries
- single round robin standings
- top 4 qualify
- 1 vs 4 and 2 vs 3 semis
- semifinal winners to final

### >= 8 Entries
- standings within Group A and Group B
- top 2 qualify from each group
- A1 vs B2, B1 vs A2
- semifinal winners to final

---

## Security and Permissions

### Authentication
- Google Auth required for organizer, helper, scheduler, referee roles
- public view may be open or tokenized by tournament slug

### Authorization
Firestore security rules enforce:
- public users: read-only limited collections
- referees: read assigned/current matches and create score submissions
- helpers: limited operational updates
- schedulers/organizers: write matches/courts/running order
- admins: full tournament control

### Sensitive Collections
- roles
- auditLogs
- scoreSubmissions
- settings

These should not be readable publicly.

---

## Google Cloud Storage Usage

Use Storage for:
- generated PDFs
- print exports
- tournament banner/logo
- optional court sheet archives
- optional CSV exports

Recommended path pattern:

```text
tournaments/{tournamentId}/exports/{fileName}.pdf
tournaments/{tournamentId}/assets/{fileName}
```

---

## Suggested Flutter Modules

### Core modules
- `app_shell`
- `auth`
- `routing`
- `design_system`
- `shared_models`
- `repositories`

### Feature modules
- `tournaments`
- `entries`
- `players`
- `categories`
- `matches`
- `scheduler`
- `courts`
- `scores`
- `checkin`
- `public_view`
- `print_center`
- `audit`

### Shared utilities
- Firestore converters
- date/time formatting
- validation
- PDF generation bridge
- CSV import utilities
- search normalization

---

## Recommended State Management

Use Riverpod for:
- provider scoping by tournament
- repository injection
- Firestore stream handling
- optimistic UI where safe

Keep:
- domain models immutable
- Firestore mappers isolated
- screen controllers thin
- generation logic in services/use-cases

---

## Generation Services

Recommended service layer components:

### `EntryImportService`
- parse CSV/Google Form export
- normalize names
- create/reuse players
- create entries

### `SeedingService`
- assign automatic seeds
- validate manual edits
- snake group distribution

### `MatchGenerationService`
- generate round robin fixtures
- generate groups
- generate semis/final placeholders

### `SchedulerService`
- determine ready matches
- validate assignment constraints
- handle court unavailability impact

### `StandingsService`
- recompute category standings
- determine qualifiers
- update semifinals/final participants

### `ScoreApprovalService`
- validate score submission
- persist official games
- update match status and winner
- trigger standings recalculation

### `PrintExportService`
- assemble printable data
- generate PDFs or print layouts
- upload to Cloud Storage

---

## Recommended Firestore Index Considerations

Likely composite indexes:
- matches by categoryId + status
- matches by assignedCourtId + status
- entries by categoryId + approvalStatus
- scoreSubmissions by approvalStatus + createdAt
- standings by categoryId + groupCode + rank
- runningOrder by orderIndex
- categories by displayOrder

---

## Assumptions and Future Extensions

### Assumptions Made
- Google Form import will be batch-based, not yet real-time synchronized
- One tournament may have many organizers and helpers
- Public standings do not require authentication
- No payment processor is required in MVP
- One event date is the main use case
- All courts are functionally equivalent
- No minimum rest gap is required
- Organizer-trusted ages are acceptable

### Future Extensions
- support for mixed doubles and singles
- support for volleyball, pickleball, and badminton under one domain framework
- QR code per court or match
- WhatsApp share links
- live announcements
- richer TV mode display
- offline support
- organization/multi-tenant branding
- player history and ranking

---

## Final Build Recommendation

The best path is to build this app as an **organizer-first badminton operations platform** with a strong live scheduler at the center, then layer in public transparency and score submission flows around it. The scheduler and score approval loop are the real differentiators. The public view amplifies the value by making the event easier to navigate for everyone else.

The MVP should be judged successful if it can do the following reliably for a live tournament weekend:

- import and manage entries
- generate correct category structures
- assign and run matches across 10 courts
- prevent cross-category player conflicts
- handle temporary court outages
- accept referee scores and require organizer approval
- update standings and qualifiers correctly
- expose public standings, court assignments, and results
- print operational sheets from the same source of truth

If those are delivered cleanly, the application will already replace a large amount of manual organizer effort and become a strong foundation for future tournament products.
