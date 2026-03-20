---
name: typo3-project-upgrade
description: "Use when upgrading a deployed TYPO3 project/instance to a new LTS version — migrating site configuration, TypoScript, templates, Docker infrastructure, and database. Not for extension code upgrades (use typo3-extension-upgrade instead)."
---

# TYPO3 Project Upgrade

Systematic approach for upgrading deployed TYPO3 project instances across major versions.

> **Scope**: Project-level upgrades (site config, TypoScript, templates, infrastructure, DB).
> For extension code upgrades, use `typo3-extension-upgrade`.

## When to Use

- Upgrading a TYPO3 website from one LTS to another (v11→v12, v12→v13, v13→v14)
- Migrating sys_template records to Site Sets (v13+)
- Upgrading Bootstrap Package across major versions (v12→v14→v16)
- Migrating BS4→BS5 styling

## Migration Phases

1. **Inventory** — 2. **Infrastructure** — 3. **Site Sets** — 4. **Visual Parity** — 5. **Review Cycles**

## Phase 1: Inventory

Before touching code, document what exists: sys_template records (`root`, `include_static_file`, constants, config), content element types, installed extensions.

## Phase 2: Infrastructure (Docker)

TYPO3 needs ImageMagick — without it, ALL images serve unprocessed originals (10-30x larger). Install it, configure GFX settings, then `TRUNCATE sys_file_processedfile` and clear `_processed_/`.

## Phase 3: sys_template → Site Sets (v13+)

Structure: `packages/my-site/Configuration/Sets/MySite/` with `config.yaml`, `settings.yaml`, `setup.typoscript`, optional `constants.typoscript`.

**config.yaml** — declare dependencies (e.g. `bootstrap-package/full`, `georgringer/news`). Reference from site config's `dependencies`.

**CRITICAL**: Delete ALL sys_template records when using site sets. A surviving `root=1` template with `include_static_file` overrides site sets, causing "No page configured for type=0".

**settings.yaml** — map old TypoScript constants to new settings. SCSS variables via `plugin.bootstrap_package.settings.scss.*` (colors, link-decoration, min-contrast-ratio, navbar colors). Prefer SCSS variables over CSS overrides — check BS5 `_variables.scss` for `!default` variables.

**Per-page behavior**: Use TypoScript conditions (`[traverse(page, "uid") == X]`) instead of per-page sys_template records.

## Phase 4: Bootstrap Package v12→v16 / BS4→BS5

**Contrast**: BS5 `color-contrast()` with `min-contrast-ratio: 4.5` may change text colors. Set to `3` to restore v11 behavior. Cards inside colored frames need CSS variable overrides.

**Navigation**: Split link/button for dropdowns (accessibility). Hover dropdowns removed (restore via CSS on `.nav-item:hover > .dropdown-menu`).

**Sticky header flicker** ([#1468](https://github.com/benjaminkott/bootstrap_package/issues/1468)): Changed from `fixed` to `sticky`. Compensate height change with `margin-bottom`.

**Accept these BS5 changes**: split nav link/button, `data-bs-*` attributes, individual JS/CSS files, 3 skip links, page title site name suffix.

## Phase 5: Review Methodology

Compare old vs new site structurally (HTTP status, content element IDs, frame classes, processed images). Categorize differences as MIGRATION GAP (fix), BS5 CHANGE (accept), or CSS OVERRIDE NEEDED (document).

## Common Mistakes

| Mistake | Fix |
|---|---|
| CSS hacks instead of SCSS variables | Use `plugin.bootstrap_package.settings.scss.*` |
| Incomplete sys_template deletion | Check ALL columns or `DELETE FROM sys_template` |
| Missing ImageMagick in Docker | Images serve unprocessed (10-30x size) |
| Fighting BS5 accessibility changes | Accept split nav, skip links, semantic HTML |
