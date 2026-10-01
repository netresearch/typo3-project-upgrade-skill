<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

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

Add the [Netresearch marketplace](https://github.com/netresearch/claude-code-marketplace) once, then install the skill:

```bash
/plugin marketplace add netresearch/claude-code-marketplace
/plugin install typo3-project-upgrade@netresearch-claude-code-marketplace
```

### Manual

Copy the directory `skills/typo3-project-upgrade/` (`SKILL.md` and `references/`) to your Claude Code skills directory.

## Assessment Checkpoints

This skill includes `checkpoints.yaml` for the [automated-assessment](https://github.com/netresearch/automated-assessment-skill) framework. Run against a TYPO3 project to verify upgrade completeness:

- **9 mechanical checks**: Site set existence, sys_template cleanup, ImageMagick, GFX config, SCSS usage
- **4 LLM reviews**: Site set completeness, BS4→BS5 migration, navigation, infrastructure

## Based On

Real-world migration of [typo3-demo.netresearch.de](https://typo3-demo.netresearch.de) from TYPO3 v11 (Bootstrap Package v12) to TYPO3 v14 (Bootstrap Package v16). Upstream contributions:

- [benjaminkott/bootstrap_package#1618](https://github.com/benjaminkott/bootstrap_package/pull/1618) — Sticky header JS fix
- [benjaminkott/bootstrap_package#1619](https://github.com/benjaminkott/bootstrap_package/pull/1619) — Sticky header CSS root cause fix

## Tests

`tests/checkpoints.sh` runs every `type: command` checkpoint in `checkpoints.yaml`, and the precondition, the way the assessment runner does (`bash <<<"$cmd"` in the project root) against fixture projects it builds in a temporary directory:

- a compliant project, on which every checkpoint must pass;
- a project with a site set that misses every other check, on which TPU-02 and TPU-04 to TPU-08 must fail;
- a project whose only site sets lie under `vendor/`, `node_modules/` and `.Build/`, on which TPU-01 and TPU-08 must fail;
- a TYPO3 extension, which the precondition must reject.

It also fails when a command uses a construct the runner refuses (`||`, `&&`, `;`, backticks, `$(`, `exec`; the runner's allowlist refuses more than this test checks), when a command checkpoint lacks a passing verdict on the `good` fixture or a failing verdict on another fixture, and when fewer checks ran than expected. The `llm_reviews` prompts, `evals/evals.json` and the prose of the skill have no behavioural test; CI checks their structure.

Run the tests and the hooks from the repository root; the test needs `bash` and [yq](https://github.com/mikefarah/yq) v4:

```bash
bash tests/checkpoints.sh
pre-commit run --all-files
```

Each check prints `ok <check>`, or `FAIL <check>` followed by the expected and the found verdict; the script exits 1 when a check failed. The pre-commit hooks in `.pre-commit-config.yaml` run the skill validator, the version-parity check, markdownlint, yamllint, actionlint, JSON and YAML syntax, ruff and ShellCheck.

In CI, `tests.yml` (Skill Tests) runs every `tests/**/*.sh` on each pull request and push to `main` and marks a failing file with an error annotation. A new or changed command checkpoint comes with its expected verdicts in `tests/checkpoints.sh`, and a test that fails without the change.

## Dependencies

- **Skill:** the skill ships no code and has no runtime dependency. The checkpoint commands use `grep`, `find`, `xargs` and `head` of the system that runs the assessment.
- **Composer:** `composer.json` requires `netresearch/composer-agent-skill-plugin` (constraint `*`), the Composer plugin that installs packages of type `ai-agent-skill`. No lock file is committed (`.gitignore` excludes `composer.lock`): the package is installed as a dependency of other projects, whose lock files pin it.
- **Tests:** `tests/checkpoints.sh` needs `bash` and `yq` v4; the CI runner image provides both.
- **Pre-commit hooks:** each hook repository in `.pre-commit-config.yaml` is pinned by `rev:`.
- **CI:** the workflows call reusable workflows of `netresearch/skill-repo-skill`, `netresearch/.github` and `netresearch/typo3-ci-workflows` at `@main`; those pin their actions by commit SHA.
- **Updates:** Renovate (`renovate.json`, preset `local>netresearch/renovate-config`, with the `pre-commit` manager enabled) opens pull requests for new hook revisions; `auto-merge-deps.yml` merges dependency pull requests once the required checks pass. Composer Audit and dependency review check dependency changes on pull requests.
- **Selection:** a new dependency is added only when the tooling or the tests need it, from its upstream source (Packagist, the tool's own repository), under a licence the organisation's [findings policy](https://github.com/netresearch/.github/blob/main/SECURITY.md#handling-of-dependency-and-code-analysis-findings) accepts.

## Governance and policies

This repository follows the Netresearch organisation policies:

- [Governance](https://github.com/netresearch/.github/blob/main/GOVERNANCE.md): ownership, roles, how decisions are made and disputes resolved.
- [Roadmap](https://github.com/netresearch/.github/blob/main/ROADMAP.md): planned and explicitly excluded work for the coming year.
- [Handling of dependency and code analysis findings](https://github.com/netresearch/.github/blob/main/SECURITY.md#handling-of-dependency-and-code-analysis-findings): thresholds, deadlines and the exception process for dependency (SCA) and static analysis (SAST) findings.
- [Secret management](https://github.com/netresearch/.github/blob/main/SECURITY.md#secret-management): how CI and release credentials are stored, accessed and rotated.
- [Access roster](https://github.com/netresearch/.github/blob/main/docs/access-roster.md): who holds administrative access to this repository and the organisation.

The security assurance case for this skill and its checkpoints (threat model, trust boundaries, countermeasures and limits) is in [docs/SECURITY-ASSURANCE.md](docs/SECURITY-ASSURANCE.md).

Checks that run on pull requests in this repository:

- Every pull request: Skill Validation (`lint.yml`: skill structure, manifest sync, markdownlint of the root Markdown files, yamllint, actionlint, JSON syntax, ShellCheck, ruff, checkpoint schemas), Eval Validation (`eval-validate.yml`), Skill Tests (`tests.yml`) and the Labeler (`labeler.yml`); on pull requests to `main` that are not drafts, also the CodeRabbit review and the Copilot code review that the repository ruleset requests.
- Pull requests to `main`: `security.yml` with Composer Audit, SAST (Opengrep, `--config auto`; which findings fail the check is set by the [organisation rule](https://github.com/netresearch/.github/blob/main/SECURITY.md#static-analysis-sast)), Betterleaks secret scanning, zizmor and dependency review (`fail-on-severity: high`); Harness Verification (`harness-verify.yml`); Template Drift (`check-template-drift.yml`); CodeQL analysis of the GitHub Actions workflows through GitHub's default setup (`Analyze (actions)`) and the DCO sign-off check.
- Required for merging into `main`: Skill Validation, Eval Validation, Skill Tests, Composer Audit, SAST (Opengrep), Secret Scanning (Betterleaks), `Analyze (actions)` and DCO. GitHub secret scanning with push protection is enabled for the repository.
- Static-analysis exceptions: `labeler.yml` and `auto-merge-deps.yml` (both from the central skill template) each suppress the zizmor finding `dangerous-triggers` inline, with the reason in the comment above it, and `tests/checkpoints.sh` suppresses ShellCheck SC2016 on one line, with the reason beside it. No other exception is recorded.

## License

- Code: [MIT](LICENSE-MIT)
- Content: [CC BY-SA 4.0](LICENSE-CC-BY-SA-4.0)

Copyright (c) 2026 Netresearch DTT GmbH
