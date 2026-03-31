# Food Safety Auditor — Workflow Plan

## Overview

A food safety audit and compliance pipeline that generates HACCP-based audit checklists, executes facility inspections against FDA/HACCP standards, documents findings with severity classifications, creates corrective action plans for non-conformances, tracks remediation to closure, and produces compliance reports with trend analysis across facilities and time periods.

This is a **regulatory compliance pipeline** — food safety audits are legally mandated, and failures can mean facility shutdowns, recalls, or public health emergencies. The system runs scheduled audits (daily pre-op, weekly full facility, monthly comprehensive) and provides persistent audit history for regulatory inspections.

## Agents

| Agent | Model | Role |
|---|---|---|
| **checklist-generator** | claude-haiku-4-5 | Generates audit checklists from HACCP plans and facility profiles, tailored to audit type (pre-op, routine, comprehensive) |
| **audit-executor** | claude-sonnet-4-6 | Walks through checklist items, applies pass/fail/observation ratings, documents evidence notes and photos references |
| **finding-classifier** | claude-opus-4-6 | Decision gate — classifies findings by severity (critical/major/minor/observation), determines if facility passes or requires corrective action |
| **corrective-action-writer** | claude-sonnet-4-6 | Creates corrective action plans (CAPAs) for non-conformances, assigns responsibility, sets deadlines, writes follow-up verification steps |
| **compliance-reporter** | claude-haiku-4-5 | Produces audit summary reports, tracks trends across facilities and time periods, generates compliance certificates |

## MCP Servers

| Server | Purpose |
|---|---|
| `filesystem` | Read/write audit checklists, findings, reports, config files |
| `sequential-thinking` | Structured reasoning for finding classification and severity assessment |
| `memory` | Persistent audit history — facility baselines, past findings, corrective action tracking, trend data across runs |
| `github` | Track corrective action items as GitHub issues, close on remediation |

## Phase Pipeline

### Workflow: `facility-audit` (default)

```
1. initialize-audit       (command)    — Validate config files, create dated output dirs, set audit scope
2. generate-checklist     (agent)      — checklist-generator: build audit checklist from HACCP plan + facility profile
3. execute-audit          (agent)      — audit-executor: walk checklist, document pass/fail/observation per item
4. classify-findings      (agent)      — finding-classifier: DECISION GATE — severity rating, overall audit verdict
   └─ on rework → execute-audit       (max 2 rework attempts — incomplete evidence or ambiguous items)
   └─ on fail → generate-checklist    (restart with revised scope if checklist was wrong for facility type)
5. create-corrective-actions (agent)   — corrective-action-writer: CAPAs for all non-conformances
6. generate-audit-report  (agent)      — compliance-reporter: full audit report with findings, CAPAs, trend analysis
7. file-audit-record      (command)    — Append to audit history ledger, update facility compliance status
```

### Workflow: `daily-preop-check`

```
1. initialize-audit       (command)    — Same init, scope = "pre-op"
2. generate-checklist     (agent)      — checklist-generator: pre-operational checklist (sanitation, temperatures, equipment)
3. execute-audit          (agent)      — audit-executor: rapid pass/fail on pre-op items
4. classify-findings      (agent)      — finding-classifier: DECISION GATE — any critical = halt operations
5. generate-preop-report  (agent)      — compliance-reporter: brief pre-op clearance or hold report
6. file-audit-record      (command)    — Log pre-op result
```

### Workflow: `corrective-action-followup`

```
1. scan-open-actions      (command)    — List all open CAPAs past their deadline
2. verify-remediation     (agent)      — corrective-action-writer: check evidence of completion, verify effectiveness
3. update-capa-status     (agent)      — compliance-reporter: update status, close completed, escalate overdue
4. file-audit-record      (command)    — Update ledger with closures and escalations
```

## Decision Contract (classify-findings phase)

```json
{
  "verdict": "proceed | rework | fail",
  "reasoning": "...",
  "audit_result": "pass | conditional-pass | fail",
  "findings_summary": {
    "critical": 0,
    "major": 0,
    "minor": 0,
    "observation": 0,
    "pass": 0
  },
  "total_items_audited": 0,
  "critical_findings": ["list of critical finding descriptions"],
  "requires_immediate_action": false,
  "confidence": "high | medium | low"
}
```

Classification rules:
- **Any critical finding** → `audit_result: fail`, `requires_immediate_action: true`
- **> 3 major findings** → `audit_result: fail`
- **1-3 major findings** → `audit_result: conditional-pass` (must remediate within 48 hours)
- **Only minor/observations** → `audit_result: pass`
- **Incomplete evidence on > 20% of items** → `verdict: rework` (re-execute audit with specific items flagged)
- **Checklist doesn't match facility type** → `verdict: fail` (regenerate checklist)

## HACCP Principles Covered

| Principle | How Addressed |
|---|---|
| 1. Hazard Analysis | Checklist items derived from facility's hazard analysis document |
| 2. Critical Control Points (CCPs) | Each CCP has dedicated checklist items with critical limits |
| 3. Critical Limits | Temperature ranges, pH levels, time limits stored in config |
| 4. Monitoring Procedures | Audit verifies monitoring logs are maintained and within limits |
| 5. Corrective Actions | CAPA phase generates actions matching HACCP corrective action requirements |
| 6. Verification | Follow-up workflow verifies corrective actions were effective |
| 7. Record-Keeping | All audit data persisted to ledger and memory MCP for regulatory access |

## Finding Severity Levels

| Severity | Definition | Response Time | Examples |
|---|---|---|---|
| **Critical** | Immediate food safety hazard, potential for illness/injury | Immediate halt + fix within 24h | Pest evidence in food prep, critical temp exceedance > 2h, no handwashing, cross-contamination |
| **Major** | Significant non-conformance, systemic control failure | Fix within 48 hours | Missing temperature logs for > 24h, improper chemical storage, no allergen controls |
| **Minor** | Non-conformance unlikely to cause harm, isolated incident | Fix within 2 weeks | Single missed log entry, worn equipment that still functions, minor labeling gap |
| **Observation** | Opportunity for improvement, best practice recommendation | Optional / next audit cycle | Better placement of sanitizer stations, updated signage, staff refresher training |

## Data Flow

```
config/haccp-plans/                     ← HACCP plans per facility/product type
config/facility-profiles/              ← Facility info: type, zones, equipment, staff
config/critical-limits.yaml            ← Temperature, pH, time limits for CCPs
config/audit-schedules.yaml            ← Which facilities get which audit types when
config/capa-templates.yaml             ← Corrective action plan templates by finding type

  → data/checklists/checklist-{facility}-{date}.json    (generate-checklist)
  → data/findings/findings-{facility}-{date}.json       (execute-audit)
  → data/classifications/classified-{facility}-{date}.json (classify-findings)
  → data/capas/capa-{facility}-{date}.json              (create-corrective-actions)
  → output/reports/audit-{facility}-{date}.md           (generate-audit-report)
  → output/reports/preop-{facility}-{date}.md           (generate-preop-report)
  → output/certificates/cert-{facility}-{date}.md       (on pass — compliance certificate)
  → data/ledger/audit-ledger.json                       (cumulative audit history)
```

## Facility Zones Audited

| Zone | Key Checks |
|---|---|
| Receiving dock | Incoming temperature verification, supplier COAs, packaging integrity |
| Cold storage | Temperature monitoring (walk-in cooler < 4C, freezer < -18C), FIFO rotation, door seals |
| Dry storage | Pest control, chemical separation, off-floor storage, labeling |
| Prep areas | Handwashing compliance, cross-contamination controls, cutting board protocols |
| Cooking stations | CCP temperatures (minimum internal temps), cooking time logs |
| Cooling area | Rapid cooling verification (60C → 21C in 2h, 21C → 4C in 4h) |
| Packaging | Allergen controls, date coding, label accuracy |
| Shipping dock | Transport temperature, load integrity, vehicle cleanliness |

## Schedule

| Schedule | Cron | Workflow |
|---|---|---|
| Daily pre-op check | `0 5 * * *` | daily-preop-check (5 AM daily, before operations start) |
| Weekly facility audit | `0 9 * * 2` | facility-audit (Tuesday 9 AM) |
| Monthly comprehensive | `0 9 1 * *` | facility-audit with scope=comprehensive (1st of month) |
| CAPA follow-up | `0 14 * * 3,5` | corrective-action-followup (Wed + Fri 2 PM) |

## Sample Data Files

The example ships with:
- `config/haccp-plans/general-food-processing.yaml` — Standard HACCP plan with 4 CCPs
- `config/facility-profiles/main-facility.yaml` — Sample facility with 8 zones, equipment list, staff count
- `config/critical-limits.yaml` — FDA food code temperature limits, pH ranges, time constraints
- `config/audit-schedules.yaml` — Audit calendar mapping facilities to audit types and frequency
- `config/capa-templates.yaml` — CAPA templates for common findings (temperature exceedance, sanitation failure, documentation gap)
- `data/sample-audit/checklist-main-facility-2026-03-25.json` — Sample completed checklist showing mix of pass/fail items
- `data/sample-audit/findings-main-facility-2026-03-25.json` — Sample findings with severity classifications

## README Outline

1. What This Does — one-paragraph hook about food safety ($7B in recalls annually, 48M illnesses/year)
2. How It Works — pipeline diagram showing audit flow from checklist to certificate
3. Quick Start — `ao daemon start` and what to expect
4. Audit Types — pre-op vs routine vs comprehensive, when each runs
5. HACCP Integration — how the system maps to the 7 HACCP principles
6. Configuration — how to customize facility profiles, critical limits, CAPA templates
7. Output — sample audit report, corrective action plan, compliance certificate
8. Architecture — agent roles, decision routing, memory persistence for audit history
9. Extending — add Slack notifications for critical findings, integrate with IoT temperature sensors, multi-facility rollout

## Directory Structure

```
examples/food-safety-auditor/
├── .ao/workflows/
│   ├── agents.yaml
│   ├── phases.yaml
│   ├── workflows.yaml
│   ├── mcp-servers.yaml
│   └── schedules.yaml
├── config/
│   ├── haccp-plans/
│   │   └── general-food-processing.yaml
│   ├── facility-profiles/
│   │   └── main-facility.yaml
│   ├── critical-limits.yaml
│   ├── audit-schedules.yaml
│   └── capa-templates.yaml
├── data/
│   ├── checklists/
│   ├── findings/
│   ├── classifications/
│   ├── capas/
│   ├── sample-audit/
│   │   ├── checklist-main-facility-2026-03-25.json
│   │   └── findings-main-facility-2026-03-25.json
│   └── ledger/
│       └── audit-ledger.json
├── output/
│   ├── reports/
│   └── certificates/
├── scripts/
│   ├── init-audit.sh
│   ├── scan-open-capas.sh
│   └── file-record.sh
├── CLAUDE.md
└── README.md
```
