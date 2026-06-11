# eta Docker and OrbStack Inventory

This file is the committed, sanitized inventory extracted from current Docker and
OrbStack state on the `eta` Home Server. Raw command output belongs under
`.local/inventory/eta/` and must not be committed.

Collection and review workflow: [eta Docker and OrbStack Inventory Workflow](../docs/eta-docker-orbstack-inventory.md).

## Review status

- Last raw collection: 2026-06-11T23:07:11Z.
- Reviewer: workflow-only review; stack findings not yet distilled.
- Source raw directory: `.local/inventory/eta/docker-orbstack-20260611T230711Z/` local-only; do not commit.

## Sanitization checklist

Before adding findings here or in `services/eta/<stack>/`, confirm the reviewed
content excludes:

- [ ] secrets, tokens, passwords, cookies, auth headers, DSNs, and API keys;
- [ ] internal URLs, private hostnames, IP addresses, tailnet details, and private
      email addresses unless intentionally documented in sanitized form;
- [ ] Docker, Traefik, or Compose labels that reveal private routing or obsolete
      topology;
- [ ] private absolute paths outside documented `~/Services/<stack>/...` service
      data paths;
- [ ] environment values instead of environment-variable names;
- [ ] obsolete settings copied from broken or experimental containers;
- [ ] raw JSON, raw command output, app exports, or unreviewed dumps.

## Migration notes

Current Docker and OrbStack state is evidence for Service Definitions, not the
source of truth. Preserve only settings that support the Home Server Recovery
Contract.

### Linkding

Linkding is a Corrective Migration. Its current broken layout should not be
preserved. The Service Definition must use durable service state under
`~/Services/linkding/...` and the restore drill must prove bookmarks survive
container recreation.

## Stack findings

Add one subsection per reviewed in-scope Service Stack.

### Template

- Intended Service Stack:
- Related current containers:
- Desired durable service state paths:
- Logical database dumps or pre-backup artifacts:
- Required networks, ingress, and ports:
- Required environment-variable names:
- Secret source notes:
- Settings intentionally dropped:
- Open questions:
