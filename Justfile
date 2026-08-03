default: install lint test

install:
    uv lock --upgrade
    uv sync --all-extras --frozen --group lint

lint:
    uv run eof-fixer .
    uv run ruff format
    uv run ruff check --fix
    uv run ty check

# Runs every check even when one fails, so CI reports all breaks at once.
lint-ci:
    #!/usr/bin/env bash
    set -uo pipefail
    failed=()
    run() {
        echo "+ $*"
        "$@" || failed+=("$*")
    }
    run uv run eof-fixer . --check
    run uv run ruff format --check
    run uv run ruff check --no-fix
    run uv run ty check
    run uv run python planning/index.py --check
    if [ ${#failed[@]} -gt 0 ]; then
        printf '\nfailed checks:\n' >&2
        printf '  %s\n' "${failed[@]}" >&2
        exit 1
    fi

index:
    uv run python planning/index.py

check-planning:
    uv run python planning/index.py --check

test *args:
    uv run --no-sync pytest {{ args }}

test-ci:
    uv run --no-sync pytest --cov=. --cov-report term-missing --cov-report xml --cov-fail-under=100

test-branch:
    uv run --no-sync pytest --cov=. --cov-branch --cov-fail-under=100

# Auth via PyPI Trusted Publishing (OIDC); uv publish auto-detects the CI id-token.
publish:
    rm -rf dist
    uv version $GITHUB_REF_NAME
    uv build
    uv publish
