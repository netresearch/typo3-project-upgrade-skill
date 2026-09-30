<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# Security assurance case — typo3-project-upgrade-skill

This document states what a user can expect from this repository in terms of security, and argues why that expectation holds. Every claim names the file or setting that implements it. Reporting a vulnerability: see the [security policy](https://github.com/netresearch/.github/blob/main/SECURITY.md).

## What the repository ships

| Part | Files | Runs where |
| --- | --- | --- |
| Skill instructions for an AI agent | `skills/typo3-project-upgrade/SKILL.md`, `skills/typo3-project-upgrade/references/v13-to-v14-project-upgrade.md` | Read by the agent as instructions; not executed. The agent may run the shell and SQL commands they describe in the TYPO3 project it works on. |
| Assessment checkpoints | `skills/typo3-project-upgrade/checkpoints.yaml` | Read by an assessment runner, such as `run-checkpoints.sh` of [automated-assessment-skill](https://github.com/netresearch/automated-assessment-skill), which executes the `type: command` entries with `bash` in the root of the assessed project. The `llm_reviews` entries are prompts for a language-model reviewer; `run-checkpoints.sh` skips them. |
| Behavioural evals | `skills/typo3-project-upgrade/evals/evals.json` | Prompts and assertions for eval tooling; CI checks their structure only. |
| Package metadata | `composer.json`, `plugin.json`, `.claude-plugin/plugin.json` | Read by Composer and by Claude Code when the skill is installed. |
| Repository tooling | `.github/workflows/*.yml`, `tests/checkpoints.sh`, `.pre-commit-config.yaml` | In this repository's CI and on contributors' machines. |

The repository contains no program, runs no server and stores no data. Its executable content is the seven `type: command` checkpoints and the precondition in `checkpoints.yaml`.

## Security requirements

1. A checkpoint command only reads the assessed project: it writes, deletes and sends nothing.
2. A checkpoint reports a finding when the project does not meet it; a check that passes on every project gives false assurance.
3. The skill's instructions do not tell the user to expose a credential.
4. A change reaches `main` through a pull request with signed, signed-off commits that passes the required checks.
5. Nothing committed to this repository contains a secret.
6. A release carries the version that `.claude-plugin/plugin.json` states, and its archives can be verified against the build that produced them.

## Actors and trust boundaries

- **Operator and agent.** The agent reads `SKILL.md` and the reference and acts with the tools the operator has given it. `SKILL.md` declares no `allowed-tools`. Which commands run against a TYPO3 instance, and with which database and container rights, is decided by the agent and the operator, not by this repository.
- **Assessment runner.** A separate project. It decides how the checkpoints run; its allowlist (`lib/command-allowlist.sh` in automated-assessment-skill) refuses command chaining (`;`, `&&`, `||`, backticks, `$(`), `exec` and several destructive commands, and reports a refused checkpoint as `blocked`. That allowlist is the runner's control, not this repository's.
- **Assessed project.** Its files are input to the checkpoint commands (`grep`, `find`) and to the language model that answers the `llm_reviews` prompts.
- **Contributors to this repository.** Changes reach `main` through pull requests, checked by the workflows in `.github/workflows/`. The pre-commit hooks in `.pre-commit-config.yaml` run the same linters locally.
- **CI.** Workflows run on GitHub-hosted runners with `permissions: {}` at the top level; each job grants the scopes its reusable needs. The two `pull_request_target` callers (`auto-merge-deps.yml`, `labeler.yml`) call reusables that merge or label without checking out pull request code, as their header comments state.
- **Dependency bot.** Renovate (`renovate.json`, preset `local>netresearch/renovate-config`, `pre-commit` manager enabled) opens pull requests that bump the pinned `rev:` of the pre-commit hooks; `auto-merge-deps.yml` merges dependency pull requests once the required checks pass.

## Threats and countermeasures

| Threat | Countermeasure | Evidence |
| --- | --- | --- |
| A checkpoint changes or deletes files in the assessed project | Every command is a `grep` or `find` pipeline without `-exec`, `-delete` or an output redirection other than `2>/dev/null`; `tests/checkpoints.sh` rejects the constructs the runner refuses | `skills/typo3-project-upgrade/checkpoints.yaml`, `tests/checkpoints.sh` |
| A checkpoint never runs, or passes on every project, and an incomplete upgrade is reported as complete | `tests/checkpoints.sh` runs each command checkpoint against a compliant and a non-compliant fixture project and fails when a verdict is wrong or when a checkpoint has no expected verdict; Skill Tests runs it on every pull request | `tests/checkpoints.sh`, `.github/workflows/tests.yml` |
| Site sets of installed packages satisfy the site-set checks (TPU-01, TPU-08) | Both commands skip `vendor/`, `node_modules/` and `.Build/`; a fixture with site sets only under those directories must fail them | `checkpoints.yaml`, `tests/checkpoints.sh` |
| The checkpoints run against a TYPO3 extension and report meaningless findings | The precondition requires `"type": "project"` or `"typo3-cms-project"` in `composer.json` | `checkpoints.yaml`, `tests/checkpoints.sh` |
| A database password leaks through the process list or the shell history | The reference passes database credentials through DDEV or a MySQL option file (`--defaults-extra-file`), not through `-p` | `references/v13-to-v14-project-upgrade.md`, section 10 |
| Serialized plaintext passwords from TYPO3 14.2 stay in `be_users.uc` | The skill and the reference name the #109585 upgrade wizard for every instance that ran 14.2 | `SKILL.md` (Phase 6), `references/v13-to-v14-project-upgrade.md` |
| A change to the skill, the checkpoints or CI is merged without its checks | Branch protection of `main` requires the status checks Skill Validation, Eval Validation, Composer Audit, SAST (Opengrep), Secret Scanning (Betterleaks), `Analyze (actions)` and DCO, up to date with `main`, signed commits and resolved conversations, and blocks force pushes and branch deletion (repository settings, read 2026-09-30) | `.github/workflows/lint.yml`, `.github/workflows/eval-validate.yml`, `.github/workflows/security.yml` |
| A secret is committed | Betterleaks scans every pull request to `main` and every push to `main` (`Secret Scanning`, required). GitHub secret scanning and push protection are enabled for the repository (repository settings, read 2026-09-30) | `.github/workflows/security.yml` |
| A vulnerable dependency is added | Composer Audit (required) audits the Composer dependency; dependency review runs on pull requests to `main` with `fail-on-severity: high` | `.github/workflows/security.yml` |
| A workflow grants more than it needs or runs untrusted code | zizmor analyses the workflows (report-only, to code scanning) with the policy in `.github/zizmor.yml`: third-party actions pinned by commit SHA, `netresearch/*` reusables by ref | `.github/workflows/security.yml`, `.github/zizmor.yml` |
| A release is built from a forged tag or with a version that disagrees with `plugin.json` | The release reusable accepts only annotated tags that GitHub reports as signed, and fails when the tag differs from `.claude-plugin/plugin.json`; the `Immutable tags` ruleset is active | `.github/workflows/release.yml`; repository rulesets, read 2026-09-30 |
| A released archive is tampered with | The release reusable publishes a Cosign-signed (keyless) `SHA256SUMS.txt` and build-provenance attestations for the archives | `.github/workflows/release.yml` |

No static-analysis exception is recorded in this repository.

## Secure design principles applied

- **Least privilege:** checkpoint commands read, they never write; every workflow sets `permissions: {}` and grants each job only what its reusable needs.
- **Fail-safe defaults:** a checkpoint whose target is missing fails (TPU-02, TPU-04, TPU-05, TPU-06 on a project without `config/sites` or `docker/`) instead of passing; the precondition gates out projects that are not TYPO3 projects.
- **Economy of mechanism:** each checkpoint is one `grep` or `find` pipeline; `tests/checkpoints.sh` needs `bash`, `yq` and the `grep`, `find`, `xargs` and `head` the checkpoints call.
- **Separation of duties in CI:** validation, tests and security scans are separate workflows, and the required checks are enforced by branch protection, not by the workflows themselves.

## Dynamic analysis

The repository ships no executable input-handling code. The checkpoint commands are `grep` and `find` one-liners that an external runner executes; `tests/checkpoints.sh` runs them against fixed fixture projects. No fuzzer or other input-varying tool runs, and branch coverage does not apply. The tests are not a dynamic analysis in the OpenSSF sense.

## What a user cannot expect

- The skill gives guidance; it does not enforce it. Its instructions include destructive statements — `DELETE FROM sys_template`, `TRUNCATE sys_file_processedfile`, `rm -rf public/fileadmin/_processed_/*` — that run with the rights of whoever executes them, and the skill contains no backup step. Take a backup of the database and `fileadmin/` first.
- A passing checkpoint run is not proof of a correct upgrade. The mechanical checks look for files and strings; the `llm_reviews` answers come from a language model reading the assessed project, whose content can steer that model.
- The command allowlist that stops a checkpoint from running arbitrary commands belongs to the runner. A runner without such a list executes whatever `checkpoints.yaml` contains.
- Branch protection requires no approving review, and repository administrators are exempt from it. Skill Tests, Harness Verification, Template Drift, zizmor and dependency review run on pull requests but are not required checks (repository settings, read 2026-09-30).
- The reusable workflows are referenced at `@main` of `netresearch/skill-repo-skill`, `netresearch/.github` and `netresearch/typo3-ci-workflows`, so a change there applies here without a change in this repository.
- Security fixes follow the supported-versions rules of the organisation's security policy; older releases may not receive them.
