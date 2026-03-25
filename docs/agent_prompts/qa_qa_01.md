# QA Prompt: QA-01

You own `QA-01` in `C:\Users\Raj\Projects\TamilTournament`.

Goal:

- establish baseline Playwright smoke coverage for Milestone 1 shell routes after `FND-02` is integrated

Primary references:

- `docs/implementation_tickets_multi_agent.md`
- `docs/orchestrator_kickoff_runbook.md`
- `C:\Users\Raj\.codex\skills\playwright-interactive\SKILL.md`

Constraints:

- do not edit code
- report only to the orchestrator
- use browser-testable Flutter web runtime, not `flutter run -d chrome`

Required runtime:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 7357
```

Deliverables:

- smoke inventory for route reachability and role gating
- baseline desktop and mobile screenshots for organizer, assistant, referee, and public shells
- reproducible startup notes

Acceptance:

- QA can launch the app and exercise shell-level navigation reliably
- baseline route coverage exists for milestone regressions

Required report format:

- pass or fail summary
- owning ticket ID
- severity
- exact repro steps
- screenshots
- route or viewport context
- recommendation on whether the issue belongs to builder-a, builder-b, or integration
