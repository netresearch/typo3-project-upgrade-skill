#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Runs every `type: command` checkpoint in
# skills/typo3-project-upgrade/checkpoints.yaml against fixture projects and
# checks the verdict: each command must pass on a project that meets the check
# and fail on one that does not. A command that exits 0 either way can never
# report a finding, so it fails this test.
#
# It also rejects the command chaining and `exec` that the assessment runner
# refuses to execute (automated-assessment-skill,
# scripts/lib/command-allowlist.sh): a refused command is reported as
# "blocked" and never runs. The runner's allowlist refuses more than this
# check does, so passing it does not prove the runner accepts a command.
#
# The commands run the way the runner runs them: `bash <<<"$cmd"` from the
# project root. Needs bash and yq (mikefarah, v4).

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CHECKPOINTS="$ROOT/skills/typo3-project-upgrade/checkpoints.yaml"

if ! command -v yq >/dev/null 2>&1; then
    echo "FAIL yq (mikefarah, v4) is required to read $CHECKPOINTS"
    exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

PASSED=0
FAILED=0

ok() {
    PASSED=$((PASSED + 1))
    echo "ok $1"
}

not_ok() {
    FAILED=$((FAILED + 1))
    echo "FAIL $1"
    echo "  expected: $2"
    echo "  found:    $3"
}

# --- fixtures ---------------------------------------------------------------

# good: a v13+ project that meets every mechanical checkpoint.
mkdir -p "$TMP/good/packages/site/Configuration/Sets/Site" "$TMP/good/config/sites/main" "$TMP/good/docker"
printf '{"name": "acme/site", "type": "project"}\n' > "$TMP/good/composer.json"
printf 'name: acme/site\ndependencies:\n  - bootstrap-package/full\n' > "$TMP/good/packages/site/Configuration/Sets/Site/config.yaml"
printf 'page.10 = TEXT\n' > "$TMP/good/packages/site/Configuration/Sets/Site/setup.typoscript"
printf 'base: /\ndependencies:\n  - acme/site\n' > "$TMP/good/config/sites/main/config.yaml"
printf 'FROM php:8.3-fpm\nRUN apt-get install -y imagemagick\n' > "$TMP/good/docker/Dockerfile"
printf 'mysql -e "DELETE FROM sys_template"\n# GFX processor = ImageMagick\n' > "$TMP/good/docker/entrypoint.sh"

# bad: a project with a site set that misses every other check.
mkdir -p "$TMP/bad/packages/site/Configuration/Sets/Site" "$TMP/bad/config/sites/main"
printf '{"name": "acme/site", "type": "project"}\n' > "$TMP/bad/composer.json"
printf 'name: acme/site\n' > "$TMP/bad/packages/site/Configuration/Sets/Site/config.yaml"
printf 'page.cssInline.10.value = .x { color: red !important; }\n' > "$TMP/bad/packages/site/Configuration/Sets/Site/setup.typoscript"
printf 'base: /\n' > "$TMP/bad/config/sites/main/config.yaml"

# vendor: the only site sets are installed packages, not the project's own.
mkdir -p "$TMP/vendor/vendor/bk2k/bootstrap-package/Configuration/Sets/Full" \
    "$TMP/vendor/node_modules/x/Configuration/Sets/X" "$TMP/vendor/.Build/y/Configuration/Sets/Y"
printf '{"name": "acme/site", "type": "project"}\n' > "$TMP/vendor/composer.json"
for f in vendor/bk2k/bootstrap-package/Configuration/Sets/Full node_modules/x/Configuration/Sets/X .Build/y/Configuration/Sets/Y; do
    printf 'name: bootstrap-package/full\n' > "$TMP/vendor/$f/config.yaml"
done

# extension: a TYPO3 extension, which the precondition must gate out.
mkdir -p "$TMP/extension"
printf '{"name": "acme/ext", "type": "typo3-cms-extension"}\n' > "$TMP/extension/composer.json"

# --- expected verdicts --------------------------------------------------------

# "<id> <fixture>" -> pass | fail. Every command checkpoint needs a "good" row
# that passes and at least one row that fails, so a checkpoint added without
# both fails the coverage check below.
declare -A EXPECT=(
    ["TPU-01 good"]=pass ["TPU-01 bad"]=pass ["TPU-01 vendor"]=fail
    ["TPU-02 good"]=pass ["TPU-02 bad"]=fail
    ["TPU-04 good"]=pass ["TPU-04 bad"]=fail
    ["TPU-05 good"]=pass ["TPU-05 bad"]=fail
    ["TPU-06 good"]=pass ["TPU-06 bad"]=fail
    ["TPU-07 good"]=pass ["TPU-07 bad"]=fail
    ["TPU-08 good"]=pass ["TPU-08 bad"]=fail ["TPU-08 vendor"]=fail
    ["precondition good"]=pass ["precondition extension"]=fail
)

verdict() {
    local dir=$1 cmd=$2
    if (cd "$dir" && bash <<<"$cmd" >/dev/null 2>&1); then
        echo pass
    else
        echo fail
    fi
}

# Constructs the runner refuses (lib/command-allowlist.sh): command chaining
# and `exec`, which also matches `find -exec`.
refused() {
    local cmd=$1
    # shellcheck disable=SC2016  # the single quotes are the point: match a literal `$(`
    [[ "$cmd" == *'||'*|| "$cmd" == *'&&'* || "$cmd" == *';'* || "$cmd" == *'`'* || "$cmd" == *'$('* ]] && return 0
    [[ "$cmd" =~ exec[[:space:]] ]] && return 0
    return 1
}

check() {
    local id=$1 cmd=$2 key fixture want got fails=0
    if refused "$cmd"; then
        not_ok "$id has no chaining or exec" "no ||, &&, ;, backtick, \$( or exec" "$cmd"
    else
        ok "$id has no chaining or exec"
    fi
    for key in "${!EXPECT[@]}"; do
        [[ "$key" == "$id "* ]] || continue
        fixture=${key#"$id "}
        want=${EXPECT[$key]}
        [[ "$want" == fail ]] && fails=$((fails + 1))
        got=$(verdict "$TMP/$fixture" "$cmd")
        if [[ "$got" == "$want" ]]; then
            ok "$id $want on $fixture"
        else
            not_ok "$id on $fixture" "$want" "$got"
        fi
    done
    if [[ "${EXPECT["$id good"]:-}" != pass ]]; then
        not_ok "$id has a passing \"good\" row in tests/checkpoints.sh" "pass" "${EXPECT["$id good"]:-none}"
    fi
    if [[ $fails -eq 0 ]]; then
        not_ok "$id has a failing row in tests/checkpoints.sh" "at least one" "none"
    fi
}

# --- run -------------------------------------------------------------------

COMMANDS=0
while IFS=$'\t' read -r id cmd; do
    COMMANDS=$((COMMANDS + 1))
    check "$id" "$cmd"
done < <(yq '.mechanical[] | select(.type == "command") | [.id, .target] | @tsv' "$CHECKPOINTS")

PRECONDITION=$(yq '.preconditions[] | select(.type == "command") | .pattern' "$CHECKPOINTS")
check precondition "$PRECONDITION"

# An aborted extraction must not read as a clean run: every row of EXPECT has
# to have been checked, plus one allowlist check per command.
EXPECTED=$((${#EXPECT[@]} + COMMANDS + 1))
if [[ $COMMANDS -eq 0 ]]; then
    not_ok "command checkpoints found" "at least one" "0"
fi
if [[ $((PASSED + FAILED)) -ne $EXPECTED ]]; then
    not_ok "number of checks" "$EXPECTED" "$((PASSED + FAILED))"
fi

echo "$PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]]
