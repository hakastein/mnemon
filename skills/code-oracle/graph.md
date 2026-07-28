# Graph-Assisted Scoping with code-review-graph

[code-review-graph](https://github.com/tirth8205/code-review-graph) (MIT) builds a persistent structural graph of the codebase — functions, classes, imports, call sites — with Tree-sitter, stored in SQLite under `.code-review-graph/`. 40+ languages. Fully local, no API keys, no model calls on the core path.

Division of labor: **the graph answers "which files matter and how they connect"; the oracle answers "what this code means."** But the graph is reachable two different ways, and they are NOT interchangeable:

- **CLI** (`build`, `update`, `status`, `detect-changes`, `visualize`) — builds/refreshes the graph and answers **diff-scoped** questions. `detect-changes` turns a git diff into an impact / reading-list panel. That is the *only* query the CLI exposes — there is no CLI subcommand for arbitrary symbol-level questions.
- **MCP server** (`code-review-graph serve`) — the only way to ask **symbol-level structural questions**: "who calls X", impact radius around an arbitrary symbol, architecture overview, review context. These are MCP tools (`query_graph_tool`, `traverse_graph_tool`, `get_impact_radius_tool`, `get_review_context_tool`, `get_architecture_overview_tool`, `get_minimal_context_tool`, `detect_changes_tool`), not CLI subcommands.

So **"who calls X?" is not a CLI capability.** Without the MCP server registered it falls back to grep / the oracle's own reading — the CLI cannot answer it.

## Setup (once per repo)

1. `command -v code-review-graph` — if missing, offer to install it: `pipx install code-review-graph` (pipx isolates its dependency pins; core install is light — no embeddings extras needed). It is the strongly recommended companion to this skill; see the plugin README's install section for alternatives (`uv tool install`, plain `pip`).
2. `code-review-graph status` — check whether a graph exists and is fresh.
3. `code-review-graph build` — first build (fast: ~130ms per 1.1k files). After that, `code-review-graph update` refreshes incrementally.
4. Make sure `.code-review-graph/` is in the project's `.gitignore` (add it if you create the graph).

### Enabling the MCP server (recommended for structural questions)

Symbol-level structural queries ("who calls X", impact radius around a symbol, architecture overview) are **MCP-only** — the CLI cannot answer them. When the session leans on them, **recommend the user register the MCP server and wait for their explicit confirmation before running anything.** The plugin never rewrites the user's MCP configuration unprompted; recommending and then acting on a yes is the workflow, not a silent install.

Recommend exactly this **surgical** form — a bare `code-review-graph install` *also* generates platform-native skill files, hooks, and injects instructions into `CLAUDE.md`/`AGENTS.md`, which collides with this skill:

```
code-review-graph install --platform claude-code --no-skills --no-hooks --no-instructions
```

That registers **only** the MCP server for Claude Code (swap `--platform` on other runtimes; `--dry-run` first to show the user what it will write). Once the user confirms and it's registered, the structural tools (`get_impact_radius_tool`, `get_review_context_tool`, `get_architecture_overview_tool`, `query_graph_tool`, `detect_changes_tool`, …) are available directly — prefer them for structural questions. Keep impact queries bounded with `CRG_MAX_IMPACT_NODES` / `CRG_MAX_IMPACT_DEPTH` if results get large; narrow the exposed surface with `--tools` / `CRG_TOOLS`.

## Queries to Use

| Question | How | Needs MCP? |
|---|---|---|
| What changed and what does it impact? | `code-review-graph detect-changes --brief` — risk panel for the current diff | No — CLI |
| Graph shape / freshness | `code-review-graph status`; `visualize` for an HTML export | No — CLI |
| Reading list for a diff | `detect-changes` on the relevant diff | No — CLI |
| Who calls X / what depends on Y? | `get_impact_radius_tool` / `query_graph_tool` | **Yes — MCP** (else grep / oracle) |
| Impact radius / reading list for an *area* (not a diff) | `get_impact_radius_tool` / `get_review_context_tool` | **Yes — MCP** (else `detect-changes` on a diff, or scope by hand) |
| Architecture overview | `get_architecture_overview_tool` | **Yes — MCP** |

Run the CLI queries yourself (output is small) or hand them to the oracle / recon subagent. Without the MCP server the graph still earns its keep for **diff-scoped** work via `detect-changes`; symbol-level Q&A degrades to grep or the oracle reading the code — don't pretend the CLI answered it.

The graph isn't only for the working project — it works on **any repo root**, including an external repo you've cloned for research. When a research task means broad reading of someone else's codebase, the move is: ask the user → clone the whole repo → `code-review-graph build` on the clone → scope the oracle's reading list from the graph, exactly as below. That turns "read an unfamiliar repo" into "read these 6 files."

## The Pattern

1. Graph: given a change (CLI `detect-changes`) or an area of interest (MCP `get_review_context_tool` / `get_impact_radius_tool`), which symbols and files are in the blast radius? → a concrete file list (typically a handful instead of a directory).
2. Oracle: spawn it with exactly that list to read fully.
3. Structural follow-ups during work ("who calls this?", "what depends on that module?") → MCP graph tools **if registered**, else grep or the oracle — never a guess dressed up as a graph answer.
4. Semantic follow-ups ("why does this retry twice?", "where is the invariant enforced?") → the live oracle via `SendMessage`.

## Caveats

- The CLI has no JSON output mode; output is human/LLM-readable text. Parse it as prose, don't script against it.
- **The CLI cannot answer symbol-level structural questions** — only `detect-changes` (diff-scoped) and `status`. "Who calls X" / impact radius around an arbitrary symbol require the MCP server; without it, fall back to grep / the oracle.
- Flow detection and some metrics are conservative/Python-centric — treat impact lists as a strong prior, not ground truth. If the oracle's reading contradicts the graph, trust the read code.
- A stale graph misleads: after big rebases or generated-code churn, `code-review-graph update` before querying.
