# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development environment

All work happens inside a Guix container. Start it from the repo root:

```bash
./bin/env-start
```

This drops you into a hermetic bash session with all packages pinned via `etc/channels.scm` and `etc/manifest.scm`. Commands that call `inside_container_check` will fail outside this container. Environment variables (paths, ports, secrets) are sourced from `etc/bash-dev-profile`.

Secrets live in `etc/secret.gpg` (GPG-encrypted). Plaintext defaults are in `etc/bash-dev-profile`; the real values overwrite them at container startup.

## Key commands (run inside the container)

```bash
# Start the full application (frontend + backend + DB)
,app-start <frontend-git-url>

# Start only the backend with an IEx REPL
,backend-iex-start

# Run backend tests
cd backend && mix test

# Run a single test file
cd backend && mix test test/path/to/file_test.exs

# Code quality
cd backend && mix credo
cd backend && mix dialyzer
cd backend && mix sobelow

# Find all TODOs
,todos

# Synchronize fork with upstream
,synchronize-with-upstream
```

## bin/ dispatch model

All scripts in `bin/` (except `env-start`) are symlinks to `bin/actor`. The `actor` script reads `$0` to determine which command was requested and dispatches accordingly. Adding a new command means adding a symlink and a new `elif` branch in `actor`.

## Architecture

**Stack:** Elixir/Phoenix (backend) + Node/Vite (frontend, cloned separately at runtime) + PostgreSQL + Guix (environment).

**Backend** (`backend/`) is a Phoenix 1.7 app with LiveView, Ecto/PostgreSQL, and Bandit as the HTTP server. The module namespace is `Backend.*` and `BackendWeb.*`.

**Emacs** (`emacs.d/`) is the canonical editor. It is launched automatically when the container starts, opening `README.org`. Configuration is in `emacs.d/init.el`; packages are declared in `etc/manifest.scm` and installed by Guix.

**OS / VM / Deployment** (`os/`, `vm/`, `deployment/`) — Guix System declarations for local QEMU VMs and remote VPS deployment via `guix deploy`.

## Specification-driven development

Every non-trivial piece of code has a corresponding specification written in org-mode (usually under `doc/`). Cross-references use UUIDs:

- `[[id:uuid]]` — defines a location (this is the thing)
- `[[ref:uuid][Name]]` — references a location (go to the thing)

Elixir modules record their spec in `@moduledoc`:

```elixir
@moduledoc """
[[id:module-uuid][Id]] implements [[ref:spec-uuid][SpecName]]
"""
```

Specifications describe *what*; implementations describe *how*. Specs must never reference implementations.

## Task workflow

Tasks live in `doc/backlog.org` as org headings with states `TODO → DOING → DONE` (also `FAILED`, `CANCELED`). Each task has an `:ID:` UUID property. To work on a task: set its state to `DOING` and `:OWNER:` to your identifier, implement it, mark it `DONE`, then send a PR.

PR checklist (from `doc/contributing.org`): code compiles, formatted, tests pass, credo/dialyzer/sobelow clean, documentation updated, task marked DONE.
