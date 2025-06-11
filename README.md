# Course-Tooling Hub

_Agentic Course Deployment System – tooling hub_

## Why this repo exists

* Provides **reusable GitHub Actions workflow** `reusable-deploy-workflow.yml`
* Hosts **templates** (Pandoc HTML, CSS, etc.)
* Stores the **Baseline Architectural Constitution** (immutable ruleset)

## Quick-start (local developer)

1. `git clone git@github-work:<org>/course-tooling.git`
2. `export AGENTIC_ENV_ROOT=$HOME/Agentic/env`
3. `export AGENTIC_STATE_ROOT=$HOME/Agentic/state`
4. `source ./scripts/bootstrap-env.sh`  # sets CDS_ENV_ROOT / CDS_STATE_ROOT
5. Run `./scripts/validate-architecture.sh` – success = ready.

## Repository layout

```
course-tooling/
├── .github/workflows/        # reusable-deploy-workflow.yml
├── templates/                # lesson.html, style.css, …
├── baseline/                 # immutable constitution (Baseline.md)
├── scripts/                  # bootstrap-env.sh, validate-architecture.sh
└── docs/                     # design notes, ADRs
```

## How to add a course

1. `gh repo create <course>-src --private`
2. `gh repo create <course>-site --public`
3. In `<course>-src`, copy `.github/workflows/deploy.yml`:
   ```yaml
   name: Publish course site
   on: [push]
   jobs:
     call:
       uses: <org>/course-tooling/.github/workflows/reusable-deploy-workflow.yml@baseline-v1
       with:
         PUBLIC_REPO: <org>/<course>-site
       secrets: inherit
   ```
4. Push → site appears at `https://<org>.github.io/<course>-site/`

## Compliance

`validate-architecture.sh` checks:

* agent ↔ MCP heartbeats
* no path literals
* cds_agent is loaded

Run it locally + CI; **failures block merge**.

## Support

Open an issue with the label `architecture` for Baseline-related questions; use `tooling` for workflow or template bugs.
