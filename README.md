# Mnemon

[![CI](https://github.com/hakastein/mnemon/actions/workflows/ci.yml/badge.svg)](https://github.com/hakastein/mnemon/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fhakastein%2Fmnemon%2Fmain%2F.claude-plugin%2Fplugin.json&query=%24.version&label=version&color=blue)](CHANGELOG.md)
[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-d97757)](https://github.com/hakastein/mnemon)

**Persistent code & research oracles for Claude Code and Codex.** Stop burning your main context window on investigation: spawn a subagent that reads the material *fully* into its own window — local files, web pages, a public-API reference, a whole cloned repo — keep it alive, and ask it questions. It answers with `file:line` / `URL` citations while your context stays clean. Optionally scoped by a [graphify](https://github.com/Graphify-Labs/graphify) structural graph that tells the oracle exactly which files matter.

> μνήμων — "mindful, remembering". The oracle remembers the code so your main agent doesn't have to.

## Install

```
/plugin marketplace add hakastein/mnemon
/plugin install mnemon@mnemon
```

### Install graphify (strongly recommended)

The graph half of mnemon is powered by [graphify](https://github.com/Graphify-Labs/graphify). Without it the oracle still works, but it has to guess its reading list with Glob/Grep; with it, reading lists come from real blast-radius analysis over a symbol-level graph of your codebase. Install it — this is most of the value.

Requires Python 3.10+. Pick one:

```bash
pipx install graphifyy     # recommended: isolated env, avoids dependency-pin conflicts
uv tool install graphifyy  # same idea, via uv
pip install graphifyy      # plain pip, if you know your environment
```

(The PyPI package is `graphifyy` while the `graphify` name is being reclaimed upstream — the CLI it installs is `graphify`.)

The skill builds the per-repo graph itself on first use with `graphify extract . --code-only` — AST-only, fully local, **no API key** — and keeps `graphify-out/` out of your commits. If the tool is missing when the skill needs it, the skill will offer to install it for you.

**Structural questions are answered by the CLI.** "Who calls X?" is `graphify affected "X"`; a scoped reading list is `graphify query "<question>"`; `path`, `explain`, and `god-nodes` cover the rest. No server, no round-trip, no fallback to grep.

Two things worth knowing:

- **The full extraction pass calls an LLM.** `graphify extract .` runs a semantic pass over docs, PDFs and images against a configured backend. `--code-only` skips it entirely, which is what the skill uses by default — it won't spend your API budget to scope a reading list.
- **Skip `graphify install`.** That command installs graphify's *own* Claude Code skill and registers it in `~/.claude/CLAUDE.md`; `graphify claude install` additionally writes `PreToolUse` hooks into `.claude/settings.json`. Those compete with this skill. Mnemon only ever uses the bare CLI. If you want graphify's skill too, that's a deliberate choice to make yourself.

Optionally, the same graph can be served over MCP (`python -m graphify.serve graphify-out/graph.json`, needs the `mcp` extra) for in-session tools instead of CLI calls. The skill recommends it and waits for your OK — it never rewrites your MCP config unprompted. It's ergonomics; the CLI already answers everything.

## Codex CLI (and other runtimes)

The oracle pattern isn't Claude-Code-specific — it needs one capability: a subagent thread that stays addressable across follow-ups. [Codex CLI](https://developers.openai.com/codex/cli) has it, so mnemon ships a Codex plugin manifest alongside the Claude one and shares a single `skills/` dir between them. Tool names are adapted at read time, not by forking the skill.

- **Install** via Codex's plugin/marketplace mechanism; the manifest (`.codex-plugin/plugin.json`) points at the same `./skills/`.
- **Enable subagents** — the oracle is dispatched with `spawn_agent`, which needs multi-agent mode. Add to `~/.codex/config.toml`:
  ```toml
  [features]
  multi_agent = true
  ```
- **Tool mapping** lives in [`skills/code-oracle/references/codex-tools.md`](skills/code-oracle/references/codex-tools.md): `Agent`/`Task` → `spawn_agent`/`wait_agent`/`close_agent`; the live oracle's `SendMessage` follow-ups → re-prompting the same open agent thread (`/agent` to switch/inspect) — keep it open, don't `close_agent` between questions. That open thread is what makes the live oracle (Mode B) work on Codex.
- **graphify** is unchanged — a standalone CLI that runs identically under any agent.

Other runtimes follow the same recipe: where they offer re-queryable subagent threads, Mode B works; where they don't, the skill degrades honestly to a single richer recon pass rather than faking persistence.

## What you get

- **`mnemon:code-oracle` skill** — auto-invoked when the agent is about to read many/large files, grep fragments, or WebFetch page after page instead of understanding. Routes between two modes:
  - *Live oracle*: a persistent subagent loads an area — a code module **or one research topic** (a public API, "the current state of X", an unfamiliar repo, a DB schema) — returns a map + its `agentId`; every follow-up goes to the same agent via `SendMessage`. No re-reading, no context burn.
  - *One-shot recon*: bounded diagnostics or lookups ("why did this fail?", "what's this API's auth flow?") with a strict `Ran / Found / Analysis / Recommended` report.
- **`mnemon:oracle` agent** — the oracle persona: reads whole files/pages (never fragments), answers with precise `file:line` / `URL` citations, never pastes content back, never edits, never mutates. For broad reading of an unfamiliar repo it proposes cloning it + building a graph, rather than fetching it page by page.
- **Graph-assisted scoping** — with [graphify](https://github.com/Graphify-Labs/graphify) installed (see above), the skill uses its blast-radius analysis to compute the oracle's reading list (`graphify query`), and answers structural questions ("who calls X?" → `graphify affected`) straight from the graph instead of spawning anything. For research, `graphify clone <url>` + a code-only extract turns an unfamiliar repo into a six-file reading list.

## The rules the skill enforces

- Investigation reads belong in a subagent's context, not yours.
- One live oracle per code area; follow-ups via `SendMessage`, never a fresh spawn.
- The oracle locates (`file:line`); **you** read and edit the slice yourself.
- Mutations (`kill`/`rm`/deploy/migrations) never go to subagents.
- Structural questions go to the graph; semantic questions go to the oracle.

## Design

See [docs/DESIGN.md](docs/DESIGN.md) for the full rationale, architecture, and roadmap.

## Contributing

Issues and PRs are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the
workflow and local checks, and the [Code of Conduct](CODE_OF_CONDUCT.md). Since
Mnemon's behavior depends on the harness and model, bug reports should include
your environment — the [issue templates](https://github.com/hakastein/mnemon/issues/new/choose)
ask for it.

## Credits

- [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) (MIT) — the structural-graph engine this plugin integrates with (referenced, not bundled).

## License

[MIT](LICENSE)
