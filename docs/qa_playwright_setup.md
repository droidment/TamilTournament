# Playwright QA Setup

This repo includes a minimal Playwright smoke harness for the role-view surfaces.

## Install

```bash
npm install
npx playwright install chromium
```

## Run

```bash
npm run test:e2e
```

Targeted smoke run:

```bash
npm run qa:role-shells
```

## Runtime

The Playwright config starts Flutter web using:

```bash
flutter run -d web-server --web-hostname localhost --web-port 7357
```

If the server is already running on that port, Playwright reuses it.

## Current coverage

- root organizer shell reachability
- assistant shell route reachability
- referee shell route reachability
- public slug route reachability
- desktop and mobile-width smoke execution

This is the initial QA harness for Milestone 1 and Milestone 2 shell-level validation. The current Flutter web headless setup is reliable for route/title smoke checks, but not yet deterministic enough for richer semantic assertions across every shell. Authenticated assistant and referee interaction coverage should be added next once stable test credentials or emulator-backed seeded fixtures are available.
