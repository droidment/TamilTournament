# Agent Prompts

These prompt files are derived from:

- `docs/implementation_tickets_multi_agent.md`
- `docs/orchestrator_kickoff_runbook.md`

They are intended for the Milestone 1 execution wave:

- `ORCH-01`
- `FND-01`
- `FND-02`
- `QA-01`

Files:

- `orchestrator_milestone_1.md`
- `builder_a_fnd_01.md`
- `builder_b_fnd_02.md`
- `qa_qa_01.md`

Usage rules:

- orchestrator owns ticket state and user updates
- builder-a owns data, models, services, and rules
- builder-b owns routing, guards, and shell surfaces
- QA stays parked until shell routes are integrated and runnable
- builders must not take overlapping write scopes in the same round
