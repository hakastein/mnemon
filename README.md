# Mnemon

**Persistent code oracles for Claude Code.** Stop burning your main context window on investigation: spawn a subagent that reads the files *fully* into its own window, keep it alive, and ask it questions — it answers with `file:line` citations while your context stays clean. Optionally scoped by a [code-review-graph](https://github.com/tirth8205/code-review-graph) structural graph that tells the oracle exactly which files matter.

> μνήμων — "mindful, remembering". The oracle remembers the code so your main agent doesn't have to.

## Install

```
/plugin marketplace add hakastein/mnemon
/plugin install mnemon@mnemon
```

### Install code-review-graph (strongly recommended)

The graph half of mnemon is powered by [code-review-graph](https://github.com/tirth8205/code-review-graph). Without it the oracle still works, but it has to guess its reading list with Glob/Grep; with it, reading lists come from real blast-radius analysis over a symbol-level graph of your codebase, and structural questions ("who calls X?") are answered in milliseconds without spawning anything. Install it — this is most of the value.

Requires Python 3.10+. Pick one:

```bash
pipx install code-review-graph     # recommended: isolated env, avoids dependency-pin conflicts
uv tool install code-review-graph  # same idea, via uv
pip install code-review-graph      # plain pip, if you know your environment
```

That's the whole setup — fully local, no API keys, no extras needed. The skill builds the per-repo graph itself on first use (`code-review-graph build`) and keeps `.code-review-graph/` out of your commits. If the tool is missing when the skill needs it, the skill will offer to install it for you.

## What you get

- **`mnemon:code-oracle` skill** — auto-invoked when the agent is about to read many/large files or grep fragments instead of understanding. Routes between two modes:
  - *Live oracle*: a persistent subagent loads an area of the codebase, returns a map + its `agentId`; every follow-up goes to the same agent via `SendMessage`. No re-reading, no context burn.
  - *One-shot recon*: bounded diagnostics ("why did this fail?") with a strict `Ran / Found / Analysis / Recommended` report.
- **`mnemon:oracle` agent** — the oracle persona: reads whole files (never fragments), answers with precise citations, never pastes files back, never edits, never mutates.
- **Graph-assisted scoping** — with [code-review-graph](https://github.com/tirth8205/code-review-graph) installed (see above), the skill uses its blast-radius analysis to compute the oracle's reading list and answers structural questions ("who calls X?") from the graph instead of spawning anything.

## The rules the skill enforces

- Investigation reads belong in a subagent's context, not yours.
- One live oracle per code area; follow-ups via `SendMessage`, never a fresh spawn.
- The oracle locates (`file:line`); **you** read and edit the slice yourself.
- Mutations (`kill`/`rm`/deploy/migrations) never go to subagents.
- Structural questions go to the graph when one exists; semantic questions go to the oracle.

## Design

See [docs/DESIGN.md](docs/DESIGN.md) for the full rationale, architecture, and roadmap.

## Credits

- [tirth8205/code-review-graph](https://github.com/tirth8205/code-review-graph) (MIT) — the structural-graph engine this plugin integrates with (referenced, not bundled).
- [obra/superpowers](https://github.com/obra/superpowers) — the plugin/marketplace structure this repo follows.

## License

[MIT](LICENSE)
