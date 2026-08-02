# AGENTS.md — TYPO3 Project Upgrade Skill

Upgrading a **deployed TYPO3 instance** across major LTS versions: site
configuration, TypoScript, templates, Docker infrastructure and the database.
Extension *code* upgrades are a different skill — see `typo3-extension-upgrade`.

## Repo Structure

```
├── skills/typo3-project-upgrade/
│   ├── SKILL.md                                   # Skill definition and triggers
│   ├── checkpoints.yaml                           # Mechanical assessment checks
│   ├── evals/evals.json                           # Behavioural evals
│   └── references/
│       └── v13-to-v14-project-upgrade.md          # The v13 → v14.3 procedure
├── .claude-plugin/plugin.json                     # Plugin manifest
├── composer.json                                  # Packagist distribution
└── README.md
```

## Commands

No Makefile and no build step — this repo is documentation plus metadata.

- `pre-commit run --all-files` — the full local gate (yamllint, markdownlint,
  skill validation, version parity)
- CI runs the same checks through the shared reusables in `.github/workflows/`

## Conventions

- `SKILL.md` has a hard **500-word cap**, counted over the whole file including
  frontmatter. Detail belongs in `references/`, not in the skill body.
- The version in `.claude-plugin/plugin.json`, `composer.json` and `SKILL.md`
  metadata must match; CI fails on drift.
- Split licensing: MIT for code, CC-BY-SA-4.0 for prose. Both LICENSE files
  stay in place.
- Shared workflows come from `netresearch/.github/templates/skill` and are
  byte-governed by `check-template-drift`. Fix them upstream, not here; record
  a deliberate exception in `.github/template.yaml` under `intentional-drift:`.
- Every commit is signed off (`git commit -s`) — DCO is enforced in CI.

## Domain facts that keep biting

- **v14.3 is the current LTS** (released 2026-04-21). Bugfix releases are
  14.3.1, 14.3.2 — there is no "v14.4 LTS".
- A project upgrade is not an extension upgrade: site sets, TypoScript
  includes and the container stack change independently of extension code.

## Where to look first

- What the skill does and when it triggers → `skills/typo3-project-upgrade/SKILL.md`
- The actual upgrade procedure → `skills/typo3-project-upgrade/references/v13-to-v14-project-upgrade.md`
- What CI enforces → `.github/workflows/` and `skills/typo3-project-upgrade/checkpoints.yaml`
