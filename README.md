# Mnemon

[![CI](https://github.com/hakastein/mnemon/actions/workflows/ci.yml/badge.svg)](https://github.com/hakastein/mnemon/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fhakastein%2Fmnemon%2Fmain%2F.claude-plugin%2Fplugin.json&query=%24.version&label=version&color=blue)](CHANGELOG.md)
[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-d97757)](https://github.com/hakastein/mnemon)

**A research oracle for Claude Code and Codex.** When a task needs a large body of documentation or another project's source, mnemon briefs a separate agent to hold that material in its own window and answer your questions about it with URL / `path:line` citations. Your context gets the answers, never the pages. For broad reading of an external repo, a [graphify](https://github.com/Graphify-Labs/graphify) graph over the clone scopes what the oracle reads.

> μνήμων — "mindful, remembering". The oracle remembers the material so your main agent doesn't have to.

## Install

```
/plugin marketplace add hakastein/mnemon
/plugin install mnemon@mnemon
```

### Install graphify (optional)

[graphify](https://github.com/Graphify-Labs/graphify) scopes the oracle's reading list when the research covers a whole external repo. Without it the oracle reads the clone unscoped. Requires Python 3.10+:

```bash
uv tool install graphifyy   # or: pipx install graphifyy
```

(The PyPI package is `graphifyy`; the CLI it installs is `graphify`.) The skill builds the graph with `graphify extract <clone> --code-only` — AST-only, local, no API key — and uses only the bare CLI. `graphify install` / `graphify claude install` put graphify's own competing skill and hooks in place; skip them unless you want that skill deliberately.

## Codex CLI (and other runtimes)

The skill describes what to do, not which tool to call, so one `skills/` dir serves every runtime. [Codex CLI](https://developers.openai.com/codex/cli) installs it through `.codex-plugin/plugin.json`; enable subagents in `~/.codex/config.toml`:

```toml
[features]
multi_agent = true
```

Keep the oracle's thread open between questions — that open thread is what lets it answer follow-ups from what it already read. On a runtime that can't address an agent twice, the skill puts every question into the first brief.

## What you get

- **`mnemon:code-oracle` skill** — triggers when a task needs research into material outside the current project: a large body of documentation or an external repo. The current project's own code stays in your window.
- **`mnemon:oracle` agent** — reads each source whole, returns a map, and answers follow-ups with citations. Read-only.
- **Graph scoping** — for broad reading of an external repo: clone, `graphify extract --code-only`, `graphify query` for the reading list; `affected` / `path` / `explain` for structural questions.

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
