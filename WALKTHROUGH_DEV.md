# Native Nix Development Workflow

## A practical model for organizing projects, environments, and services on an Arch + Home Manager workstation

## 1. Purpose

This document defines a development workflow for a machine that is:

* **Arch Linux** at the host level
* **Home Manager** for the personal user environment
* **Nix flakes** for per-project toolchains
* **containers** for local project services when needed

The goal is to make every repository easy to understand and easy to operate.

A repo should feel like this:

```bash
cd ~/Source/personal/some-project
nix develop
just launch
just test
just build
```

Or, once `direnv` is enabled:

```bash
cd ~/Source/personal/some-project
just launch
just test
just build
```

The machine stays stable. Each repo stays reproducible. Services stay isolated. Daily work stays intuitive.

---

## 2. Core Principles

### 2.1 The machine should stay boring

The host machine should not become a giant mutable pile of project-specific dependencies.

Arch and Home Manager should provide the stable personal environment:

* shell
* editor
* terminal
* git
* common CLI tools
* desktop environment

Projects should not rely on hidden global toolchains.

### 2.2 Every repo should be self-describing

A serious repo should answer three questions immediately:

* how do I enter the environment
* how do I run it
* how do I test it

If the answer is not obvious, the repo is not organized yet.

### 2.3 Nix should own toolchains, not your whole life

For this workflow, Nix is primarily used to define **per-project development environments**.

That means:

* Rust versions live in the repo
* Node/pnpm versions live in the repo
* project-specific CLIs live in the repo
* native build dependencies live in the repo

### 2.4 Containers should be for services

Containers are useful for:

* databases
* caches
* queues
* vector stores
* model backends
* object stores

Containers are not the default place to run your editor, terminal, or entire coding session.

### 2.5 Every repo should feel the same to operate

The command vocabulary should be uniform:

```bash
just launch
just test
just build
just fmt
just lint
just up
just down
just logs
```

Different repos may do different things underneath, but the interface should stay consistent.

### 2.6 Data should not pollute source trees

Large mutable data should live outside repos.

Use repos for:

* code
* docs
* configuration
* small fixtures
* reproducible scripts

Use a separate data root for:

* datasets
* model caches
* VM images
* generated artifacts
* persistent service volumes

---

## 3. Ownership Model

This workflow works because ownership is clear.

### 3.1 Arch owns

Arch owns the machine itself:

* kernel
* drivers
* bootloader
* firmware
* system services
* graphics stack
* Docker daemon
* session/login infrastructure
* hardware integration

Arch is the platform.

### 3.2 Home Manager owns

Home Manager owns the personal environment:

* shell
* terminal
* editor
* git
* global CLI tools
* desktop preferences
* user-level app configuration
* personal user services

Home Manager is the stable user layer.

### 3.3 Per-repo Nix owns

Each repo’s flake owns that repo’s development environment:

* language toolchains
* repo-specific utilities
* native build dependencies
* environment variables
* formatters and linters
* language servers
* scripts needed only for that repo

The repo flake is the contract for entering that project.

### 3.4 Containers own local services

Containers own the stateful infrastructure that a repo depends on:

* Postgres
* Redis
* MinIO
* Kafka
* Qdrant
* Ollama
* ClickHouse
* Mailhog

If a service can be local and isolated, keep it out of the host and put it in the repo’s `compose.yaml`.

---

## 4. Top-Level Filesystem Design

## 4.1 Source root

Use:

```text
~/Source
```

That is simple, memorable, and conventional enough to be obvious.

But do not use it as a flat dump of unrelated repositories.

## 4.2 Recommended structure

```text
~/Source/
  personal/
  research/
  work/
  infra/
  experiments/
  archive/
  _templates/
  _scratch/
```

### `personal/`

Long-lived personal codebases:

* products
* libraries
* tools
* platform repos
* personal operating systems/config repos

### `research/`

Repos focused on:

* evaluations
* benchmarks
* experiments with results
* papers-with-code
* prototypes meant to answer questions rather than ship products

### `work/`

Client or employer code, separated from personal and research work.

### `infra/`

Repos for:

* deployment
* automation
* containers
* provisioning
* self-hosted services
* operational scripts

### `experiments/`

Shorter-lifecycle repos:

* shell experiments
* UI spikes
* QuickShell/DMS trials
* Rust playgrounds
* tool investigations

### `archive/`

Dead or inactive repos that still matter as reference.

### `_templates/`

Starter templates for new repos:

* minimal flake repo
* flake + services repo
* research repo
* infra repo

### `_scratch/`

Non-canonical temporary work:

* quick tests
* disposable experiments
* code not yet worthy of a real repo

## 4.3 Data root

Keep large mutable data somewhere else:

```text
~/Data/
  datasets/
  model-cache/
  docker/
  vm/
  media/
  artifacts/
```

This keeps repositories fast to clone, easy to back up, and less likely to rot under huge local junk.

---

## 5. Repository Categories

Not every repo should look identical, but every repo should belong to a recognizable class.

## 5.1 Personal product repos

Examples:

* apps
* services
* libraries
* platforms
* whitepaper-adjacent implementation repos

These are usually long-lived and should have the cleanest structure.

## 5.2 Research repos

Examples:

* benchmark harnesses
* evaluation frameworks
* experiment runners
* notebooks with code
* paper-support repos

These often need:

* scripts
* results
* experiment metadata
* maybe service dependencies

## 5.3 Infrastructure repos

Examples:

* deployment code
* self-hosting stacks
* Docker and Compose repos
* Nix/ops repos
* automation and maintenance scripts

These may not ship an “app” but should still have the same environment contract.

## 5.4 Experiment repos

Examples:

* shell spikes
* compositor experiments
* QuickShell labs
* new language playgrounds
* concept validation repos

These can be lighter, but they should still not rely on hidden global installs.

## 5.5 Archive repos

Keep them out of the active tree, but keep them accessible.

---

## 6. Standard Repository Contract

Every serious repo should contain at least:

```text
repo/
  flake.nix
  flake.lock
  .envrc
  justfile
  README.md
```

Optional:

* `compose.yaml`
* `.env.example`
* `scripts/`
* `infra/`
* `docs/`

This gives every repo:

* a reproducible environment
* a consistent command interface
* basic self-documentation

---

## 7. Standard Repo Layouts

## 7.1 Minimal library or CLI repo

```text
repo/
  flake.nix
  flake.lock
  .envrc
  justfile
  README.md
  src/
  tests/
```

Good for:

* Rust crates
* TS libraries
* CLIs
* small utilities

## 7.2 Full-stack application repo

```text
repo/
  flake.nix
  flake.lock
  .envrc
  justfile
  README.md
  compose.yaml
  apps/
  packages/
  infra/
  scripts/
```

Good for:

* web apps
* backend/frontend repos
* product codebases with local services

## 7.3 Research repo

```text
repo/
  flake.nix
  flake.lock
  .envrc
  justfile
  README.md
  notebooks/
  scripts/
  experiments/
  results/
  papers/
```

Good for:

* evaluation work
* benchmark repos
* exploratory R&D

## 7.4 Infrastructure repo

```text
repo/
  flake.nix
  flake.lock
  .envrc
  justfile
  README.md
  deploy/
  terraform/
  ansible/
  compose/
  scripts/
```

Good for:

* deployment
* service orchestration
* ops automation

---

## 8. Environment Entry Model

## 8.1 Manual entry

The baseline entry command is:

```bash
nix develop
```

This should always work.

## 8.2 Automatic entry

Use `direnv` plus `nix-direnv` so entering a repo automatically loads its development shell.

Typical `.envrc`:

```bash
use flake
```

That means your daily flow becomes:

```bash
cd ~/Source/personal/amio
just launch
just test
```

without manually invoking `nix develop` each time.

## 8.3 Recommendation

Support both:

* `nix develop` for manual correctness
* `direnv` for ergonomics

Never make the repo depend on only one of them.

---

## 9. Command Interface Standard

Use `just` as the repo’s operator-facing interface.

## 9.1 Standard commands

### `just launch`

Run the main entrypoint.

Examples:

* `cargo run`
* `pnpm dev`
* `python scripts/run.py`

### `just test`

Run the primary test suite.

Examples:

* `cargo test --workspace`
* `pnpm test`
* `pytest`

### `just build`

Build production or release artifacts.

Examples:

* `cargo build --workspace`
* `pnpm build`

### `just fmt`

Format the codebase.

### `just lint`

Run static checks.

### `just up`

Start required local services.

### `just down`

Stop local services.

### `just logs`

Tail service logs.

### `just clean`

Clean local build artifacts.

## 9.2 Rule

Keep the top-level verbs consistent across repos.
Do not invent a different command surface for every codebase unless there is a very strong reason.

---

## 10. Per-Repo Nix Design

Each repo should own its own development environment through `flake.nix`.

## 10.1 What belongs in the flake

* language runtimes
* compilers
* package managers
* build tools
* linters
* formatters
* language servers
* native dependencies

## 10.2 What should not be global

Avoid depending on globally installed:

* Rust toolchains
* Node versions
* pnpm versions
* project CLIs
* OpenSSL/SQLite build assumptions

If the repo needs it, declare it.

## 10.3 Example `flake.nix`

```nix
{
  description = "Project dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          just
          jq
          fd
          ripgrep

          rustc
          cargo
          rust-analyzer
          clippy
          rustfmt

          nodejs_24
          pnpm
          biome
          typescript-language-server
          vscode-langservers-extracted

          pkg-config
          openssl
          sqlite
          clang
          lld
        ];

        shellHook = ''
          echo "dev shell ready"
        '';
      };
    };
}
```

This is boring in a good way.

---

## 11. Container Strategy

## 11.1 Use containers for services

If the repo needs infrastructure, containerize the infrastructure.

Typical examples:

* Postgres
* Redis
* MinIO
* Mailhog
* Ollama

## 11.2 Do not containerize the whole workflow by default

You should still use:

* host editor
* host terminal
* host window manager
* host shell

The point is to keep development ergonomic while isolating services.

## 11.3 Example `compose.yaml`

```yaml
services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
      POSTGRES_DB: app
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7
    ports:
      - "6379:6379"

volumes:
  postgres-data:
```

Then the repo interface becomes:

```bash
just up
just launch
```

---

## 12. Global Tooling Baseline

Keep the Home Manager global toolset intentionally small.

Recommended globals:

* `git`
* `gh`
* `direnv`
* `just`
* `fd`
* `ripgrep`
* `jq`
* `bat`
* `eza`
* `zoxide`
* `fzf`
* editor
* terminal

This is enough to feel comfortable everywhere without making the machine secretly responsible for project logic.

---

## 13. Day-to-Day Workflow

## 13.1 Starting work

```bash
cd ~/Source/research/evals
```

If `direnv` is enabled, the environment auto-loads.

If not:

```bash
nix develop
```

Then:

```bash
just launch
```

## 13.2 Running tests

```bash
just test
```

## 13.3 Building

```bash
just build
```

## 13.4 Starting services

```bash
just up
```

## 13.5 Stopping services

```bash
just down
```

This is the exact simplicity you want.

---

## 14. New Repository Bootstrap Workflow

## 14.1 Create the repo

```bash
mkdir -p ~/Source/personal/new-project
cd ~/Source/personal/new-project
git init
```

## 14.2 Add the standard files

Create:

* `flake.nix`
* `.envrc`
* `justfile`
* `README.md`
* `.gitignore`

## 14.3 Enable the environment

```bash
direnv allow
```

or manually:

```bash
nix develop
```

## 14.4 Verify the toolchain

```bash
rustc --version
node --version
pnpm --version
just --version
```

## 14.5 Add services if needed

If the repo needs infra, add `compose.yaml`.

```bash
just up
```

Then proceed normally.

---

## 15. Data and Artifact Policy

## 15.1 Keep out of repos

Do not store these in source repos unless they are tiny fixtures:

* datasets
* model weights
* VM images
* container data volumes
* build artifacts
* generated logs/results too large to belong in git

## 15.2 Use `~/Data`

Reference external paths like:

* `~/Data/datasets/...`
* `~/Data/model-cache/...`
* `~/Data/artifacts/...`

This keeps repos small and portable.

## 15.3 Exceptions

It is fine to keep:

* sample data
* tiny fixtures
* deterministic test assets
* small benchmark inputs

inside the repo.

---

## 16. README Standard for Each Repo

Each repo README should include:

* what the repo is
* how to enter the environment
* how to launch it
* how to test it
* whether it needs services
* where persistent data lives

Minimal example:

```md
# project-name

## Enter
- `nix develop`
- or `direnv allow`

## Run
- `just launch`

## Test
- `just test`

## Build
- `just build`

## Services
- `just up` / `just down`

## Data
- Uses `~/Data/...`
```

---

## 17. Validation Checklist for Every Repo

A repo is in good shape when:

* `nix develop` works
* `.envrc` loads correctly
* `just launch` works
* `just test` works
* `just build` works
* services start with `just up` if needed
* it does not secretly depend on global language installs

If any of those fail, the repo is not yet cleanly integrated into the system.

---

## 18. Anti-Patterns to Avoid

Avoid:

* a flat `~/Source` full of unrelated repos
* hidden dependence on global Node or Rust installs
* using Docker for the whole coding experience by default
* mixing pacman, Home Manager, repo flake, and containers for the same dependency
* storing huge mutable data inside source repos
* inventing totally different `just` verbs for every repo

Prefer:

* categorized repo roots
* one obvious environment entry path
* one obvious command interface
* service isolation only where needed
* data separated from code

---

## 19. Recommended Default Policy

This is the policy I would actually use:

* all repos live under `~/Source`
* repos are categorized by intent
* every serious repo gets:

  * `flake.nix`
  * `flake.lock`
  * `.envrc`
  * `justfile`
  * `README.md`
* `nix develop` is always valid
* `direnv` is the ergonomic layer
* `just launch`, `just test`, and `just build` are the human-facing contract
* containers are used only for local services
* large mutable data lives under `~/Data`

That is the cleanest fit for your machine and your kinds of projects.

---

## 20. Future Extensions

Later, you can add:

* repo templates under `~/Source/_templates`
* a bootstrap script for creating new repos
* heavier patterns like `devenv` for larger projects
* CI that reuses the same flake and `just` commands
* category-specific conventions for research vs infra vs product repos

But do not start there. Start simple.

---

## 21. Appendix

## 21.1 Example `~/Source` tree

```text
~/Source/
  personal/
    lu-nix/
    amio/
    raia/
    graphite/
  research/
    evals/
    benchmarks/
    papers/
  infra/
    homelab/
    deploy/
  experiments/
    quickshell-lab/
    rust-playgrounds/
  archive/
    old-prototypes/
```

## 21.2 Example `.envrc`

```bash
use flake
```

## 21.3 Example `justfile`

```make
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
  @just --list

launch:
  @echo "No launch target defined yet"
  @exit 1

test:
  @echo "No test target defined yet"
  @exit 1

build:
  @echo "No build target defined yet"
  @exit 1

fmt:
  @echo "No fmt target defined yet"
  @exit 1

lint:
  @echo "No lint target defined yet"
  @exit 1

up:
  @if [ -f compose.yaml ]; then docker compose up -d; else echo "No services"; fi

down:
  @if [ -f compose.yaml ]; then docker compose down; else echo "No services"; fi

logs:
  @if [ -f compose.yaml ]; then docker compose logs -f; else echo "No services"; fi
```

## 21.4 Example repo lifecycle

```bash
cd ~/Source/personal/new-project
direnv allow
just up
just launch
just test
just build
```

This is the workflow I would standardize on.

