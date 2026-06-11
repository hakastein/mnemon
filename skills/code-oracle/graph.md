# Graph-Assisted Scoping with code-review-graph

[code-review-graph](https://github.com/tirth8205/code-review-graph) (MIT) builds a persistent structural graph of the codebase — functions, classes, imports, call sites — with Tree-sitter, stored in SQLite under `.code-review-graph/`. 40+ languages. Fully local, no API keys, no model calls on the core path.

Division of labor: **the graph answers "which files matter and how they connect"; the oracle answers "what this code means."** Use the graph to compute the oracle's reading list and to answer purely structural questions without spawning anything.

## Setup (once per repo)

1. `command -v code-review-graph` — if missing, offer to install it right away: `pipx install code-review-graph` (pipx isolates its dependency pins; core install is light — no embeddings extras needed). It is the strongly recommended companion to this skill; see the plugin README's install section for alternatives (`uv tool install`, plain `pip`).
2. `code-review-graph status` — check whether a graph exists and is fresh.
3. `code-review-graph build` — first build (fast: ~130ms per 1.1k files). After that, `code-review-graph update` refreshes incrementally.
4. Make sure `.code-review-graph/` is in the project's `.gitignore` (add it if you create the graph).

Never run `code-review-graph install` — it rewrites the user's MCP configuration. If the user wants the MCP server, they set it up themselves; the CLI output is LLM-friendly text and is enough for this skill.

## Queries to Use

Run these read-only commands yourself (output is small) or hand them to the oracle/recon subagent:

| Question | Command |
|---|---|
| What changed and what does it impact? | `code-review-graph detect-changes --brief` — risk panel for the current diff |
| Repo shape / where does X live? | `code-review-graph status` + architecture overview via MCP, or `visualize` exports |
| Reading list for area Y | `detect-changes` on the relevant diff, or impact queries around Y's symbols |

If the user has already registered the MCP server (tools like `get_review_context_tool`, `get_impact_radius_tool`, `get_architecture_overview_tool`, `detect_changes_tool` are available), prefer those — they return structured context directly. Keep impact queries bounded with `CRG_MAX_IMPACT_NODES` / `CRG_MAX_IMPACT_DEPTH` if results get large.

The graph isn't only for the working project — it works on **any repo root**, including an external repo you've cloned for research. When a research task means broad reading of someone else's codebase, the move is: ask the user → clone the whole repo → `code-review-graph build` on the clone → scope the oracle's reading list from the graph, exactly as below. That turns "read an unfamiliar repo" into "read these 6 files."

## The Pattern

1. Graph: "given this change / this area of interest, which symbols and files are in the blast radius?" → a concrete file list (typically a handful instead of a directory).
2. Oracle: spawn it with exactly that list to read fully.
3. Structural follow-ups during work ("who calls this?", "what depends on that module?") → graph, not grep, not the oracle.
4. Semantic follow-ups ("why does this retry twice?", "where is the invariant enforced?") → the live oracle via `SendMessage`.

## Caveats

- The CLI has no JSON output mode; output is human/LLM-readable text. Parse it as prose, don't script against it.
- Flow detection and some metrics are conservative/Python-centric — treat impact lists as a strong prior, not ground truth. If the oracle's reading contradicts the graph, trust the read code.
- A stale graph misleads: after big rebases or generated-code churn, `code-review-graph update` before querying.
