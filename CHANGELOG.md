# Changelog

## 0.5.0 — 2026-07-29

- **Graph engine swapped: code-review-graph → [graphify](https://github.com/Graphify-Labs/graphify).**
  Not a rename — a different engine with a different command surface, so
  `graph.md` was rewritten and every reference across `SKILL.md`, `oracle.md`,
  `README.md`, `DESIGN.md`, the manifests, and the issue templates was updated
  to the real API. Install is `pipx install graphifyy` (PyPI name while
  `graphify` is being reclaimed upstream; the CLI is `graphify`), the per-repo
  artifact is `graphify-out/` (gitignored), and the build is
  `graphify extract . --code-only`.
- **Structural queries are back on the CLI**, reversing 0.4.0's MCP-first
  story: `graphify affected "X"` answers "who calls X / what depends on Y",
  `graphify query "<q>"` returns a token-budgeted reading list, and
  `path` / `explain` / `god-nodes` cover connections and shape. The MCP server
  (`python -m graphify.serve <graph.json>`) is now optional ergonomics rather
  than the only route to symbol-level Q&A — nothing degrades to grep without it.
  There is no diff-scoped subcommand any more; derive the changed symbols from
  the diff and run `affected` on them.
- **New caveats the docs now state honestly.** A full `graphify extract .`
  dispatches a semantic LLM pass over docs/PDFs/images, so `--code-only`
  (AST-only, local, no API key) is the documented default for scoping. Graph
  edges are tagged `EXTRACTED` / `INFERRED` / `AMBIGUOUS`, and only the first
  comes from the AST — the oracle is told to verify an inferred edge before
  reporting it as a call site.
- **Never run graphify's own installers.** `graphify install` places
  graphify's competing Claude Code skill and registers it in
  `~/.claude/CLAUDE.md`; `graphify claude install` also writes `PreToolUse`
  hooks into `.claude/settings.json`. The skill, the oracle persona, and the
  README all now say mnemon uses the bare CLI only.
- **Research flow gains first-class repo cloning**: `graphify clone <url>`
  clones to `~/.graphify/repos/<owner>/<repo>` and prints the path, and
  `graphify global add` merges several project graphs into one cross-repo graph.

## 0.4.0 — 2026-07-28

- **Graph docs: MCP-first for structural queries.** Corrected a
  capability error propagated across `graph.md`, `SKILL.md`, `README.md`, and
  `DESIGN.md`: symbol-level structural questions ("who calls X?", impact radius
  around a symbol, architecture overview) are **only** answerable through
  code-review-graph's MCP server — the CLI exposes just diff-scoped
  `detect-changes` and `status`. The skill now *recommends* the user register
  the MCP server and **waits for their confirmation** (reversing the old "never
  run `install`" stance), and recommends the surgical form
  `code-review-graph install --platform claude-code --no-skills --no-hooks
  --no-instructions` so a bare `install` doesn't inject competing skills/hooks
  or edit `CLAUDE.md`/`AGENTS.md`. Without the MCP server, structural questions
  degrade honestly to the oracle / grep.

## 0.3.0 — 2026-06-15

- **Code-oracle skill: one-level-of-delegation rule.** Added a Common Mistakes
  entry making explicit that a spawned oracle/recon subagent is a leaf — it
  reads and answers, never re-invokes the skill or fans out further. Notes that
  the `mnemon:oracle` agent enforces this (no spawn tool) while the
  `general-purpose` fallback does not, so its prompt must forbid nesting.
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
- **Codex CLI support.** Ships a Codex plugin manifest (`.codex-plugin/plugin.json`) sharing the single `skills/` dir with the Claude build, plus a tool map (`skills/code-oracle/references/codex-tools.md`) adapting `Agent`/`SendMessage`/`subagent_type` to `spawn_agent`/open-thread steering/`~/.codex/agents/*.toml`. New "Platform Adaptation" section in the skill; README documents the Codex install and the `multi_agent` config.

## 0.1.1 — 2026-06-11

- code-review-graph promoted from "optional accelerator" to strongly recommended companion: dedicated install section in the README (pipx/uv/pip), and the skill now offers to install it when missing instead of silently falling back to manual scoping.

## 0.1.0 — 2026-06-11

Initial release.

- `code-oracle` skill: live-oracle and one-shot-recon modes, decision graph, prompt templates, red-flag list.
- `oracle` plugin agent: full-file reading persona with `file:line` citations, read-only tool surface.
- Optional [code-review-graph](https://github.com/tirth8205/code-review-graph) integration for graph-assisted reading-list scoping (`skills/code-oracle/graph.md`).
- Self-marketplace distribution (`/plugin marketplace add hakastein/mnemon`).
