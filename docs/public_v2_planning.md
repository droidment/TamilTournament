# Public V2 Planning

## Why This Pass

The app now has a working public tournament surface and a working volunteer-referee path. That means the next planning step should not be "how do we build public from scratch." It should be "how do we turn the current public page into the primary event-facing product surface."

This document captures the Public v2 direction based on the current codebase and the defaults now locked:

- live courts first
- both player-name and team-name search
- player utility first, with spectator-friendly live sections underneath
- volunteer referees stay sign-in gated
- volunteering auto-approves into the referee desk only

## Current State In The Repo

Public v1 already exists in [public_shell_page.dart](C:\Users\Raj\Projects\TamilTournament\lib\features\public\presentation\public_shell_page.dart).

It currently supports:

- public tournament lookup by slug or code
- tournament hero
- volunteer-referee card
- search
- live courts
- recent official results
- standings
- categories

Related supporting pieces already exist:

- published-tournament discovery on the landing page in [sign_in_page.dart](C:\Users\Raj\Projects\TamilTournament\lib\features\auth\presentation\sign_in_page.dart)
- volunteer referee provisioning in [tournament_role_repository.dart](C:\Users\Raj\Projects\TamilTournament\lib\features\tournaments\data\tournament_role_repository.dart)
- referee desk in [referee_shell_page.dart](C:\Users\Raj\Projects\TamilTournament\lib\features\referee\presentation\referee_shell_page.dart)
- organizer public-access controls in [organizers_section.dart](C:\Users\Raj\Projects\TamilTournament\lib\features\tournaments\presentation\organizers_section.dart)

So Public v2 is an experience upgrade, not a greenfield build.

## Product Goal

Public v2 should become the page people actually use during tournament day.

For players, it should answer:

- where do I play
- what court is active
- what just finished
- what category am I in
- how do I find my team or player quickly

For spectators, it should answer:

- what is happening right now
- what results are official
- which courts are live
- what divisions are in the event

For potential referees, it should answer:

- can I volunteer
- what happens if I do
- how do I open the referee desk once approved

## Public V2 Principles

### 1. Utility First

The page should prioritize tournament-day utility over generic marketing.

That means:

- live information above deep category browsing
- search visible without scrolling
- official results clearly separated from in-progress floor activity

### 2. Official Data Boundary

The public page must continue to show only official state.

Public can see:

- published tournament info
- live court assignments
- official results
- official standings
- published categories

Public must not see:

- pending score submissions
- role collections
- volunteer management internals
- audit notes
- rejected scores

### 3. Referee Handoff, Not Referee Merge

The public page is not the place to score matches.

It should:

- invite eligible users to volunteer
- explain that approval is instant when volunteering is enabled
- route approved users into `/r/:tournamentId`

It should not:

- embed score-entry controls
- expose assistant controls
- collapse referee work into the public surface

### 4. Mobile First

Most public usage will happen on phones around the venue.

That means:

- top sections must work in a single-column flow
- search and live-court access need to be reachable immediately
- dense tables should degrade into compact cards or segmented views

## Public V2 Information Architecture

Recommended page order for `/p/:publicSlug`:

1. Tournament hero
2. Volunteer referee / desk handoff card
3. Search and quick filters
4. Live courts
5. Recent official results
6. Standings / category progress
7. Categories directory

This keeps the page player-useful before it becomes browse-heavy.

## Screen And Section Plan

### 1. Tournament Hero

Keep the hero compact and informative.

Required content:

- tournament name
- venue
- event date
- current tournament status
- high-signal stats: categories, live courts, active matches, official results

Recommended improvement over current state:

- clearer "live now" emphasis
- visual separation between event identity and utility stats

### 2. Volunteer Referee Card

This stays high on the page and becomes more explicit.

States:

- signed out + volunteering enabled
  - `Sign in to volunteer as referee`
- signed in + no qualifying role + volunteering enabled
  - `Volunteer as referee`
- signed in + referee
  - `Open referee desk`
- signed in + assistant
  - `Open assistant desk`
- signed in + organizer
  - `Open organizer workspace`
- volunteering disabled
  - passive message only

The card should also explain one important rule:

- score submissions from referees still require assistant or organizer approval

### 3. Search And Quick Filters

Search should stay near the top and support:

- team/pair names
- individual player names
- category names
- match codes
- court codes

Recommended Public v2 additions:

- segmented filter chips: `All`, `Live`, `Results`, `Categories`, `Courts`
- persistent search field at the top of the scroll stack on mobile
- result grouping so search does not feel like one long undifferentiated list

### 4. Live Courts

This is the highest-priority content section.

Each court card should communicate:

- court code
- match code
- category
- teams or pairs
- current state: assigned, called, on court

Recommended Public v2 enhancement:

- group live courts before idle courts
- add a compact `starting soon` state for assigned/called matches
- keep completed results out of this section

### 5. Recent Official Results

This stays official-only.

Recommended content:

- winner
- scoreline
- category
- court, if relevant
- completion time

Recommended Public v2 enhancement:

- show the most recent 5-10 results inline
- add `View all official results` if volume becomes too large

### 6. Standings And Category Progress

This should remain useful but not dominate the home page.

Recommended approach:

- show a compact preview of standings on the home page
- route deeper table views to category detail cards or modals later if needed

If one category has no official standings yet, show a compact status note instead of an empty box.

### 7. Categories Directory

This becomes the entry point for deeper browsing.

Each category card should show:

- category name
- format
- checked-in team count
- whether standings are active

Recommended future route:

- `/p/:publicSlug/categories/:categoryId`

That route does not need to be the first Public v2 milestone, but the home page should be designed to support it.

## Referee Integration Plan

The referee flow should feel like a clean handoff from public, not a separate hidden system.

### Public To Referee Handoff

When a user volunteers successfully:

- stay on the public page
- show immediate success confirmation
- swap the CTA to `Open referee desk`
- deep-link into `/r/:tournamentId`

### Referee Desk Expectations

The referee desk should continue to be a separate operational surface, but Public v2 should assume volunteers arrive there from the public page.

That means the referee desk should be optimized for:

- court lookup
- match-code lookup
- team-name lookup
- fast score submission

The referee desk should not require prior assignment to be useful for volunteers.

## Design Direction

Public v2 should not visually resemble the organizer workspace.

Recommended visual direction:

- brighter, event-facing palette
- clearer section contrast
- stronger live-state highlighting
- less admin-panel framing
- more crowd-readable typography in the hero and live-court sections

Design tone:

- useful first
- energetic second
- never noisy

## Data And Query Requirements

Public v2 should continue to hide Firestore storage shape behind providers and repositories.

Recommended additions:

- grouped public search model instead of raw filtering inside one page widget
- public home query composition layer that returns:
  - hero summary
  - live court board payload
  - recent official results payload
  - standings preview payload
  - categories preview payload
- player-name lookup support if current entry/category data does not already expose it cleanly

## Public V2 Execution Order

### Phase 1: Home Page Upgrade

Goal:

- make the existing public home materially better without adding route sprawl

Scope:

- improve hero hierarchy
- add quick filters around search
- make live courts more prominent
- tighten results and standings previews
- improve volunteer-card messaging

### Phase 2: Search Quality

Goal:

- make search truly useful for players in the venue

Scope:

- add player-name search
- add grouped result sections
- add empty-state guidance

### Phase 3: Deeper Public Browsing

Goal:

- support deeper browsing beyond the homepage

Scope:

- category detail route
- full results route if needed
- pair/team detail route if needed

### Phase 4: Referee Handoff Polish

Goal:

- make public-to-referee transition feel first-class

Scope:

- better volunteer success state
- stronger route CTA logic by current role
- public explanation of referee responsibilities and approval flow

## Implementation Tickets

### PUB2-01: Public Home Information Hierarchy

Owner:

- builder-b

Goal:

- restructure the public home so live utility content is clearly above browse content

Write scope:

- [public_shell_page.dart](C:\Users\Raj\Projects\TamilTournament\lib\features\public\presentation\public_shell_page.dart)
- public presentation helpers

Acceptance:

- live courts appear before results, standings, and categories
- search is visually near the top
- the page reads as a tournament-day utility surface on mobile

### PUB2-02: Volunteer Card And Role Routing Polish

Owner:

- builder-b

Goal:

- make volunteer and desk-entry states clearer for signed-out, eligible, and already-authorized users

Write scope:

- [public_shell_page.dart](C:\Users\Raj\Projects\TamilTournament\lib\features\public\presentation\public_shell_page.dart)
- route helper logic if needed

Acceptance:

- users see the right CTA for their current role
- volunteer success immediately exposes `Open referee desk`
- assistant and organizer users are routed toward their own desks

### PUB2-03: Public Search Model

Owner:

- builder-a

Goal:

- move public search out of raw page filtering and into a clearer public query layer

Write scope:

- public providers
- tournament/category/match query composition

Acceptance:

- search supports team names, player names, category names, match codes, and court codes
- search results can be grouped by section rather than flattened

### PUB2-04: Live Court Board Upgrade

Owner:

- builder-b

Goal:

- make live-court cards easier to scan in the venue

Write scope:

- public court-board presentation

Acceptance:

- live or on-court matches visually outrank idle courts
- `starting soon` states are distinguishable from `on court`
- mobile scanability improves

### PUB2-05: Category Detail Route

Owner:

- builder-b with builder-a support

Goal:

- add deeper browsing from the categories directory

Write scope:

- public routes
- public category detail presentation
- public category query composition

Acceptance:

- public users can open a category-specific page
- category detail shows official standings/results only

### PUB2-06: Public QA Expansion

Owner:

- qa

Goal:

- extend browser coverage from shell reachability into real public usage

Acceptance:

- Playwright covers public landing, public tournament page, volunteer flow, and public-to-referee handoff
- QA verifies pending submissions never appear in public sections

## QA Focus

Public v2 QA should emphasize:

- mobile viewport fit
- search usefulness
- live-court readability
- volunteer flow correctness
- public-only official data boundary

Required QA scenarios:

1. Open a published tournament while signed out.
2. Verify live courts and official results render.
3. Verify volunteer CTA is sign-in gated when enabled.
4. Sign in and volunteer as referee.
5. Confirm the page changes to `Open referee desk`.
6. Enter the referee desk from the public page.
7. Verify public page never shows pending score submissions.

## Risks

### 1. Search Depth

If player names are not exposed cleanly through current read models, "search by player" may require a read-model pass rather than just UI wiring.

### 2. Category Storage Shape

Because categories are still not nested under tournament documents, deeper public browsing may become awkward if category detail logic leaks storage shape into UI code.

### 3. Public Overload

If too much data is pushed onto the home page, it will become harder to scan than the current version. The page should stay live-first.

## Recommended Next Move

The next practical step is not another broad planning pass. It is to start Phase 1 of Public v2:

- restructure the public home hierarchy
- improve volunteer-card state clarity
- make live courts more prominent
- keep results, standings, and categories as lower sections

That gives you a noticeably better public experience quickly without needing new Firestore schema changes first.
