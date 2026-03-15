# TYPO3 Project Upgrade Skill

Claude Code skill for upgrading deployed TYPO3 project instances across major LTS versions.

## Scope

This skill covers **project-level** upgrades — the deployed website, its configuration, templates, infrastructure, and database. For upgrading extension **code** to new TYPO3 APIs, use [typo3-extension-upgrade](https://github.com/netresearch/typo3-extension-upgrade-skill).

## What It Covers

- **sys_template → Site Sets**: Migrating TypoScript constants/config to TYPO3 v13+ site set YAML files
- **SCSS Variable Injection**: Using Bootstrap Package's ScssParser to override BS5 variables without CSS hacks
- **Bootstrap 4 → 5 Migration**: color-contrast, link-decoration, frame custom properties, navbar changes
- **Bootstrap Package v12→v16**: Navigation split link/button, dropdown-hover removal, position:sticky, known bugs
- **Infrastructure**: ImageMagick in Docker, GFX configuration, processed file regeneration
- **Database Cleanup**: sys_template deletion, FlexForm updates, stale record cleanup
- **Review Methodology**: Structural comparison via curl, difference categorization, visual verification

## Installation

### Claude Code (marketplace)

```bash
claude mcp add typo3-project-upgrade -- npx @anthropic-ai/claude-code-marketplace typo3-project-upgrade
```

### Manual

Copy `skills/typo3-project-upgrade/SKILL.md` to your Claude Code skills directory.

## Assessment Checkpoints

This skill includes `checkpoints.yaml` for the [extension-assessment](https://github.com/netresearch/extension-assessment-skill) framework. Run against a TYPO3 project to verify upgrade completeness:

- **9 mechanical checks**: Site set existence, sys_template cleanup, ImageMagick, GFX config, SCSS usage
- **4 LLM reviews**: Site set completeness, BS4→BS5 migration, navigation, infrastructure

## Based On

Real-world migration of [typo3-demo.netresearch.de](https://typo3-demo.netresearch.de) from TYPO3 v11 (Bootstrap Package v12) to TYPO3 v14 (Bootstrap Package v16). Upstream contributions:

- [benjaminkott/bootstrap_package#1618](https://github.com/benjaminkott/bootstrap_package/pull/1618) — Sticky header JS fix
- [benjaminkott/bootstrap_package#1619](https://github.com/benjaminkott/bootstrap_package/pull/1619) — Sticky header CSS root cause fix

## License

- Code: [MIT](LICENSE-MIT)
- Content: [CC BY-SA 4.0](LICENSE-CC-BY-SA-4.0)

Copyright (c) 2026 Netresearch DTT GmbH
