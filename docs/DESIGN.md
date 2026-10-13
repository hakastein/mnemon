# Mnemon — Design Document

*Status: v0.6.0 · 2026-09-22*

## Problem

The expensive resource in an agentic coding session is the main agent's context window. Research into material outside the project — a product's documentation, an API reference, another project's source — is the bulkiest reading an agent does, and almost none of it is needed after the answer is found. Fetching page after page into the main window burns context on material the task will never touch again, and piecing a topic together from fragments gives a keyhole view.

## Solution: the Oracle

An **oracle** is a separate agent briefed once per research topic. It reads the sources in full into its own window, returns a map, and stays addressable: every follow-up goes to the same agent, which answers from what it already holds, with citations. The main agent pays for questions and answers, never for pages.

## Scope

The oracle covers **external** material only — read, never edited. The project being changed stays in the main agent's window, including "how does this project already do X, so I can do the same": that reading informs an edit and belongs beside it. Earlier versions also routed local code navigation and diagnostics through the oracle; narrowing the skill to external research keeps its trigger unambiguous.

## Structure for external repos

For broad reading of an unfamiliar repo, [graphify](https://github.com/Graphify-Labs/graphify) (MIT) builds a symbol-level graph of the clone and answers "which files matter for this question" (`graphify query`), plus structural questions (`affected`, `path`, `explain`, `god-nodes`). The graph picks the reading list; the oracle reads it.

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
│       ├── SKILL.md         # scope and steps
│       └── graph.md         # loaded only for broad reading of a cloned repo
├── agents/
│   └── oracle.md            # the oracle persona, spawnable as mnemon:oracle
└── docs/DESIGN.md           # this file
```

## Key Decisions

1. **Describe intent, not tools.** The skill says what to do ("start the oracle", "ask the same oracle a follow-up") rather than naming Claude Code tools, so one `skills/` dir serves Claude, Codex, and any runtime with addressable agents — no per-platform tool maps.
2. **Tell the oracle what to deliver, not how to work.** The persona fixes the deliverables — full reads, a map, cited answers, read-only — and leaves the method to the agent.
3. **graphify is optional.** It helps only for broad reading of a cloned repo; the skill offers to install it and asks before cloning anything.
4. **Code-only extraction.** `--code-only` is AST-only, local, and free; a full extract spends the user's API key and is used only on request. graphify's own installers (`graphify install`, `graphify claude install`) register a competing skill and hooks, so mnemon uses the bare CLI.
5. **Mid-tier model by default.** Small models loop on tool confirmations instead of reading; a bigger model is for material that needs heavy reasoning, while window pressure is solved by one oracle per sub-topic.
6. **Honest degradation.** Without addressable agents, every question goes into the first brief instead of faking persistence by re-spawning.
7. **Self-marketplace distribution and explicit semver**, both manifests bumped together.

## Distribution

```
/plugin marketplace add hakastein/mnemon
/plugin install mnemon@mnemon
```

The skill resolves as `mnemon:code-oracle`, the agent as `mnemon:oracle`. Pre-publish checks: `claude plugin validate . --strict`; live test with `claude --plugin-dir .`.

## Non-Goals

- Navigating or editing the current project — the main agent reads what it changes.
- Vendoring or wrapping graphify (referenced, never bundled; MIT attribution in README).
- Windows-native support beyond what Claude Code itself provides (WSL works).

## Roadmap

- **Multi-oracle registry** — tracking several live oracles (topic → agent) across a long session, so the main agent reuses instead of re-briefing after summarization.
- **Research presets** — named briefs for recurring shapes (public-API reference, "state of tool X", an unfamiliar repo via clone + graph).
- **More runtime manifests** — Cursor/Gemini/Copilot, sharing the same `skills/` dir.
