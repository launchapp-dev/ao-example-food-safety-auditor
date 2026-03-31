# Food Safety Auditor — AO Example

This is an AO workflow example demonstrating a food safety audit and compliance pipeline.

## What This Does

Automates HACCP-based food facility audits:
- Generates audit checklists from HACCP plans and facility profiles
- Executes inspections across all facility zones (8 zones)
- Classifies findings by severity (critical/major/minor/observation)
- Creates corrective action plans (CAPAs) for non-conformances
- Generates compliance reports and certificates
- Tracks remediation and escalates overdue CAPAs

## Agents

| Agent | Role |
|---|---|
| `checklist-generator` | Builds checklists from HACCP plans and facility profiles |
| `audit-executor` | Walks checklist, assigns pass/fail/observation per item |
| `finding-classifier` | Decision gate — severity classification and audit verdict |
| `corrective-action-writer` | Creates CAPAs, assigns responsibility, tracks in GitHub |
| `compliance-reporter` | Generates audit reports, certificates, trend analysis |

## Workflows

- `facility-audit` — Full HACCP-based inspection (default)
- `daily-preop-check` — Rapid pre-op sanitation check before operations
- `corrective-action-followup` — Review open CAPAs, verify remediation

## Config Files

- `config/haccp-plans/` — HACCP plans with hazard analysis and CCPs
- `config/facility-profiles/` — Facility zones, equipment, contacts
- `config/critical-limits.yaml` — FDA Food Code temperature and time limits
- `config/capa-templates.yaml` — CAPA templates by finding type

## Data Flow

```
config/ → data/checklists/ → data/findings/ → data/classifications/
       → data/capas/ → output/reports/ → output/certificates/
       → data/ledger/ (cumulative audit history)
```

## Environment Variables

Copy `.env.example` to `.env` and fill in:
- `GITHUB_PERSONAL_ACCESS_TOKEN` — For creating GitHub issues to track CAPAs
