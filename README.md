# Mnemon

**Persistent code oracles for Claude Code.** Stop burning your main context window on investigation: spawn a subagent that reads the files *fully* into its own window, keep it alive, and ask it questions — it answers with `file:line` citations while your context stays clean. Optionally scoped by a [code-review-graph](https://github.com/tirth8205/code-review-graph) structural graph that tells the oracle exactly which files matter.

> μνήμων — "mindful, remembering". The oracle remembers the code so your main agent doesn't have to.

## Install

```
/plugin marketplace add hakastein/mnemon
/plugin install mnemon@mnemon
```

## What you get

- **`mnemon:code-oracle` skill** — auto-invoked when the agent is about to read many/large files or grep fragments instead of understanding. Routes between two modes:
  - *Live oracle*: a persistent subagent loads an area of the codebase, returns a map + its `agentId`; every follow-up goes to the same agent via `SendMessage`. No re-reading, no context burn.
  - *One-shot recon*: bounded diagnostics ("why did this fail?") with a strict `Ran / Found / Analysis / Recommended` report.
- **`mnemon:oracle` agent** — the oracle persona: reads whole files (never fragments), answers with precise citations, never pastes files back, never edits, never mutates.
- **Graph-assisted scoping** — if [code-review-graph](https://github.com/tirth8205/code-review-graph) is installed (`pipx install code-review-graph`), the skill uses its blast-radius analysis to compute the oracle's reading list and answers structural questions ("who calls X?") from the graph instead of spawning anything. Fully optional; everything works without it.

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
