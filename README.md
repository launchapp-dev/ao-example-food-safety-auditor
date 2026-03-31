# Food Safety Auditor

An autonomous food safety audit and compliance pipeline built with [AO](https://github.com/launchapp-dev/ao). Runs HACCP-based facility inspections, classifies findings, generates corrective action plans, and produces regulatory-ready compliance reports — fully automated on a schedule.

Food safety failures cost the industry $7 billion in recalls annually and cause 48 million illnesses in the US each year. This pipeline automates the audit process so no checklist is skipped, every non-conformance gets a CAPA, and regulators always have a complete audit trail.

## How It Works

```
HACCP Plan + Facility Profile
         ↓
  Generate Checklist          (claude-haiku-4-5)
         ↓
  Execute Audit               (claude-sonnet-4-6)
         ↓
  Classify Findings           (claude-opus-4-6) ← Decision Gate
    ├── rework → re-audit     (max 2 attempts)
    └── fail → new checklist
         ↓
  Create CAPAs                (claude-sonnet-4-6) → GitHub Issues
         ↓
  Generate Report             (claude-haiku-4-5)
         ↓
  File Audit Record           (audit ledger + memory)
```

## Quick Start

```bash
# 1. Clone and enter the project
git clone https://github.com/launchapp-dev/ao-example-food-safety-auditor
cd ao-example-food-safety-auditor

# 2. Set up environment
cp .env.example .env
# Edit .env with your GitHub token

# 3. Start AO daemon
ao daemon start --autonomous

# 4. Run a facility audit
ao workflow run facility-audit

# 5. Watch it run
ao daemon stream --pretty
```

Outputs appear in:
- `output/reports/` — Full audit reports (Markdown)
- `output/certificates/` — Compliance certificates (on pass)
- `data/capas/` — Corrective action plans (JSON)

## Audit Types

| Type | Trigger | Scope |
|---|---|---|
| **Pre-Op Check** | Daily 5 AM | Sanitation, temperatures, equipment readiness — go/no-go for operations |
| **Routine Audit** | Weekly Tuesday 9 AM | Full facility inspection across all 8 zones |
| **Comprehensive** | Monthly 1st | Extended scope with trend analysis and CAPA review |
| **CAPA Follow-Up** | Wed + Fri 2 PM | Review open corrective actions, verify remediation |

## HACCP Integration

The pipeline maps directly to all 7 HACCP principles:

| Principle | Implementation |
|---|---|
| 1. Hazard Analysis | Checklists derived from facility's hazard analysis document |
| 2. Critical Control Points | Each CCP has dedicated checklist items (cooking temp, cold storage, rapid cooling, metal detection) |
| 3. Critical Limits | FDA Food Code limits stored in `config/critical-limits.yaml` |
| 4. Monitoring Procedures | Audit verifies monitoring logs are maintained and within limits |
| 5. Corrective Actions | CAPA phase creates actions matching HACCP requirements |
| 6. Verification | Follow-up workflow verifies corrective action effectiveness |
| 7. Record-Keeping | All data persisted to audit ledger for regulatory access |

## Finding Severity Levels

| Level | Definition | Response Time |
|---|---|---|
| **Critical** | Immediate food safety hazard (pest, critical temp exceedance, no handwashing) | Halt + fix within 24h |
| **Major** | Systemic control failure (missing CCP logs > 24h, improper chemical storage) | Fix within 48h |
| **Minor** | Isolated incident unlikely to cause harm | Fix within 2 weeks |
| **Observation** | Improvement opportunity | Optional |

## Agents

| Agent | Model | Role |
|---|---|---|
| `checklist-generator` | claude-haiku-4-5 | Generates facility-specific checklists from HACCP plans |
| `audit-executor` | claude-sonnet-4-6 | Walks checklist, documents pass/fail/observation per item |
| `finding-classifier` | claude-opus-4-6 | Classification decision gate — severity and overall verdict |
| `corrective-action-writer` | claude-sonnet-4-6 | Creates CAPAs, assigns owners, sets deadlines, files GitHub issues |
| `compliance-reporter` | claude-haiku-4-5 | Generates reports, certificates, and trend analysis |

## Configuration

### Add a New Facility

1. Create `config/facility-profiles/<facility-id>.yaml` — zones, equipment, contacts
2. Add the facility to `config/audit-schedules.yaml`
3. Customize checklists by adding to the HACCP plan if needed

### Adjust Critical Limits

Edit `config/critical-limits.yaml` to match your jurisdiction's food code requirements. The defaults follow FDA Food Code 2022.

### CAPA Templates

Edit `config/capa-templates.yaml` to customize corrective action templates for your facility's common finding types.

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GITHUB_PERSONAL_ACCESS_TOKEN` | Yes | For creating GitHub issues to track CAPAs. Needs `repo` scope on `launchapp-dev/ao-example-food-safety-auditor`. |

## AO Features Demonstrated

- **Decision gates** — `finding-classifier` uses `decision_contract` to control workflow branching
- **Rework loops** — audit re-executed if evidence is incomplete (max 2 attempts)
- **Memory persistence** — audit history and CAPA tracking across runs
- **Scheduled workflows** — daily pre-op, weekly routine, monthly comprehensive, CAPA follow-up
- **Multi-workflow orchestration** — 3 separate workflows with shared phases
- **Command phases** — bash scripts for init and record-filing steps
- **GitHub integration** — CAPA tracking as GitHub issues with labels and deadlines

## Extending

- **Slack notifications** — Alert QA manager instantly on critical findings using `@modelcontextprotocol/server-slack`
- **IoT temperature sensors** — Poll sensor APIs in command phases to populate CCP data automatically
- **Multi-facility rollout** — Parameterize facility ID via `{{dispatch_input}}` to run audits across a fleet
- **Regulatory export** — Add a phase to format audit data as FDA FSMA-compliant XML
