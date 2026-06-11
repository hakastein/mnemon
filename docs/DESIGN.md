# Mnemon — Design Document

*Status: v0.2.0 · 2026-06-11*

## Problem

The expensive resource in an agentic coding session is the main agent's context window. Understanding a codebase the naive way — reading files into the main context, or worse, grepping fragments to dodge full reads — has two failure modes:

1. **Context burn.** A 2000-line file read once stays in the window for the rest of the task. Three such reads and the session degrades: summarization kicks in, earlier decisions get lossy.
2. **Fragmentary understanding.** Grep/awk gymnastics against a file the agent refuses to read fully produces a keyhole view. The agent acts on fragments and misses the invariant two screens away.

Subagents flip the economics: a subagent can read the same 2000 lines and the main agent pays only for the answer. But the stock fan-out pattern (spawn → answer → die) wastes the subagent's loaded context — the next question about the same module re-reads everything.

## Solution: the Oracle Pattern

**Mnemon** (μνήμων, "mindful") ships a skill and an agent that make subagent context *persistent and addressable*:

- An **oracle** is a subagent spawned once per code area. It reads the relevant files **fully** into its own window, returns a short map plus its `agentId`, and stays alive.
- Every follow-up question goes to the same oracle via `SendMessage(to: agentId)`. The harness resumes the agent with its prior context intact, so each answer costs the main agent a question and an answer — never the files.
- Answers cite `file:line`, so when the main agent needs to edit, it Reads only the exact slice it will change. Rule: *you must read what you edit; the oracle locates, you edit.*

A second, degenerate mode covers bounded diagnostics: **one-shot recon**, where a subagent runs read-only commands and returns a `Ran / Found / Analysis / Recommended` synthesis, then dies. The skill's decision graph routes between the two (and tells the agent when to skip delegation entirely — single facts, mutations, files it is about to edit).

## The Missing Half: Structure

The oracle is strong on semantics and blind to global structure. It cannot cheaply answer "who calls this?", "what breaks if I change X?", "what is the dependency shape of this repo?" — and, critically, it cannot tell you *which files it should be reading* in the first place. Scoping the reading list by directory name over-reads or under-reads.

[code-review-graph](https://github.com/tirth8205/code-review-graph) (tirth8205, MIT) solves exactly this gap: a fully local Tree-sitter pipeline that builds a persistent symbol-level graph (functions, classes, imports, call sites) in SQLite, for 40+ languages, with no API keys and no model calls on the core path. Its blast-radius analysis turns a diff or an area of interest into a precise list of affected files and symbols.

The division of labor mnemon encodes:

| Question | Answered by |
|---|---|
| Which files matter for this change/area? | graph (impact radius, review context) |
| Who calls X / what depends on Y? | graph |
| What does this code mean / why is it like this? | oracle |
| Where exactly do I edit? | oracle → `file:line` → main agent reads the slice |

The graph computes the oracle's reading list; the oracle reads exactly those files. On a typical change this turns "read the directory" into "read these 6 files."

## Architecture

```
mnemon/
├── .claude-plugin/
│   ├── plugin.json          # Claude manifest (name=mnemon → skill namespace)
│   └── marketplace.json     # self-marketplace, source: "./"
├── .codex-plugin/
│   └── plugin.json          # Codex manifest, "skills": "./skills/" (shared dir)
├── skills/
│   └── code-oracle/
│       ├── SKILL.md         # decision graph, modes, prompt templates, platform adaptation
│       ├── graph.md         # loaded on demand when code-review-graph is present
│       └── references/
│           └── codex-tools.md  # Claude→Codex tool-name map (Agent→spawn_agent, …)
├── agents/
│   └── oracle.md            # the oracle persona, spawnable as mnemon:oracle
└── docs/DESIGN.md           # this file
```

The `skills/` dir is the single source of truth; each platform ships only a thin manifest pointing at it and a `references/<platform>-tools.md` tool map. Skills are never forked per runtime.

**`skills/code-oracle`** is the entry point, auto-invoked via its `description` when the main agent is about to burn context on investigation. It carries the decision graph (delegate vs. do-it-yourself), both prompt templates, and the anti-pattern list ("red flags") that catches the agent mid-rationalization.

**`agents/oracle`** bakes the oracle persona into a plugin agent: read fully, map, answer with citations, never edit, never mutate, never dump files. Read-only tool surface (`Read, Grep, Glob, Bash`). The skill spawns it via `subagent_type: mnemon:oracle`, with a documented fallback to `general-purpose` + inline prompt template for runtimes without plugin agents.

**`skills/code-oracle/graph.md`** is progressive disclosure: SKILL.md stays lean; the graph workflow (setup, query table, the scoping pattern, caveats) loads only when `code-review-graph` is actually on the PATH.

## Key Decisions

1. **code-review-graph is strongly recommended, but not a hard dependency.** It carries most of the scoping value, so the README documents its installation front-and-center and the skill, on finding it absent (`command -v` check once per session), *offers to install it on the spot* (`pipx install code-review-graph`) rather than silently degrading. Manual Glob/Grep scoping remains as the fallback only when the user declines or installation is impossible — the oracle pattern must still function on a bare Claude Code install. The plugin never installs software without asking.
2. **Never run `code-review-graph install`.** That command rewrites the user's MCP configuration — a plugin has no business mutating it. If the user registers the MCP server themselves, the skill prefers those tools; otherwise the CLI's LLM-friendly text output is sufficient.
3. **pipx over pip** in the install suggestion: crg pins `mcp`/`fastmcp` ranges that can conflict in shared Python environments.
4. **No embeddings extras.** The structural graph alone covers the scoping use case; `[embeddings]`/`[wiki]` pull heavy deps or API keys for marginal gain here.
5. **`Sonnet`-class default for oracles, never haiku-class.** Small models loop on tool-confirmation behavior instead of reading. `opus` only when the *code* demands heavy reasoning; window pressure is solved by sharding into multiple oracles per sub-area, not by a bigger model.
6. **Honest degradation.** If the runtime lacks `SendMessage`/addressable agents, the skill says to fall back to one richer recon pass rather than fake a persistent oracle by re-spawning.
7. **Self-marketplace distribution** (the obra/superpowers pattern): both `plugin.json` and `marketplace.json` live in `.claude-plugin/`, the single plugin entry points at `"./"`. Install is two commands, no extra marketplace repo.
8. **Explicit semver.** `version` in plugin.json gates updates to deliberate bumps; users on `/plugin marketplace update` don't get every WIP commit. Both manifests carry the same version and must be bumped together.
9. **A "read" is any bulky input, not just a local file.** v0.2 generalizes the oracle from code to external research: web pages, public-API references, DB schemas, unfamiliar repos. The failure mode is identical — WebFetching page after page into the main context is the web equivalent of grep-fragment gymnastics — so the same delegation applies. "Read fully" stays *per source* (one file/page/schema whole), never "ingest a whole repo." For broad repo reading the main agent asks the user, clones the whole repo, and builds a code-review-graph over the clone to scope the oracle — the graph half works on any repo root, not just the working project.
10. **Cross-platform by shared `skills/` + tool maps, not forks** (the obra/superpowers pattern). One skills dir; per-platform thin manifests point at it; a `references/<platform>-tools.md` table adapts Claude tool names at read time. The only capability the oracle truly requires is a re-queryable subagent thread (Claude `SendMessage`, Codex open agent threads). Where a runtime lacks it, the skill degrades to one richer recon pass rather than faking persistence — the same honest-degradation rule as for `SendMessage`-less Claude runtimes.

## Distribution

```
/plugin marketplace add hakastein/mnemon
/plugin install mnemon@mnemon
```

The skill resolves as `mnemon:code-oracle`, the agent as `mnemon:oracle`. Pre-publish checks: `claude plugin validate . --strict`; live test with `claude --plugin-dir .`.

## Non-Goals

- Vendoring or wrapping code-review-graph (it is referenced, never bundled; MIT attribution in README).
- Editing through the oracle — the calling agent must read what it edits.
- Windows-native support beyond what Claude Code itself provides (WSL works).

## Roadmap

- **Graph bootstrap hook** — optional `SessionStart` hook that runs `code-review-graph update` when a graph already exists, so queries never hit a stale graph.
- **Recon presets** — named Mode A templates for common diagnostics (port conflicts, disk usage, failed service).
- **Multi-oracle registry** — a convention for tracking several live oracles (area → agentId) across a long session, so the main agent re-uses instead of re-spawning after summarization.
- **MCP tool allowlist preset** — a documented `CRG_TOOLS` setting exposing only the 4–6 graph tools the oracle workflow needs.
- **More runtime bridges** — Cursor/Gemini/Copilot manifests + tool maps and a SessionStart bootstrap, following the same shared-`skills/` pattern now in place for Claude and Codex. (Codex landed first because it has the re-queryable subagent threads the live oracle needs.)
- **Research presets** — named Mode-B templates for recurring research shapes (public-API reference, "state of tool X", read-an-unfamiliar-repo via clone+graph).
