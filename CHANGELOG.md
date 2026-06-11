# Changelog

## Unreleased

- **Open-source scaffolding.** Added community-health and CI infrastructure:
  `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), GitHub
  issue forms + pull-request template, and `dependabot` for GitHub Actions.
- **CI pipeline** (`.github/workflows/ci.yml`): validates all JSON manifests,
  enforces version consistency across manifests, lints Markdown, and runs an
  informational link check. `main` is protected (PR + passing checks required).
- **Release tooling.** `scripts/bump-version.sh` sets the version across every
  manifest at once and verifies they agree (`--check`, run in CI).
- Repo hygiene: committed `.gitignore`, `.editorconfig`, `.gitattributes`,
  `.markdownlint.json`, and README status/version/license badges.

## 0.2.0 — 2026-06-11

- **Research oracle.** The oracle now covers external research, not just local code: web pages, public-API references, DB schemas, and unfamiliar GitHub repos. Single-topic web research goes to a live oracle (or one-shot recon) instead of burning the main context on page-after-page WebFetch. The `oracle` agent gains `WebFetch`/`WebSearch`.
  - Repo reading is scoped: fetch a few raw files when that's enough; for broad coverage, ask the user before cloning, then clone the whole repo and build a code-review-graph over it to scope the reading list. "Read fully" is per-source (one file/page/schema whole), never "ingest the entire repo."
- **Codex CLI support.** Ships a Codex plugin manifest (`.codex-plugin/plugin.json`) sharing the single `skills/` dir with the Claude build (the obra/superpowers cross-platform pattern), plus a tool map (`skills/code-oracle/references/codex-tools.md`) adapting `Agent`/`SendMessage`/`subagent_type` to `spawn_agent`/open-thread steering/`~/.codex/agents/*.toml`. New "Platform Adaptation" section in the skill; README documents the Codex install and the `multi_agent` config.

## 0.1.1 — 2026-06-11

- code-review-graph promoted from "optional accelerator" to strongly recommended companion: dedicated install section in the README (pipx/uv/pip), and the skill now offers to install it when missing instead of silently falling back to manual scoping.

## 0.1.0 — 2026-06-11

Initial release.

- `code-oracle` skill: live-oracle and one-shot-recon modes, decision graph, prompt templates, red-flag list.
- `oracle` plugin agent: full-file reading persona with `file:line` citations, read-only tool surface.
- Optional [code-review-graph](https://github.com/tirth8205/code-review-graph) integration for graph-assisted reading-list scoping (`skills/code-oracle/graph.md`).
- Self-marketplace distribution (`/plugin marketplace add hakastein/mnemon`).
