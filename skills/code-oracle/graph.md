# Graph-Assisted Scoping with graphify

[graphify](https://github.com/Graphify-Labs/graphify) (MIT) builds a persistent knowledge graph of a corpus — functions, classes, imports, call sites via Tree-sitter, plus concepts and relationships extracted from docs, PDFs and images — and writes it to `graphify-out/graph.json` alongside a `GRAPH_REPORT.md`, an interactive `graph.html`, and a SHA256 cache so re-runs only process changed files.

Division of labor: **the graph answers "which files matter and how they connect"; the oracle answers "what this code means."**

Two ways in, and unlike other graph engines they overlap almost completely:

- **CLI** (`extract`, `update`, `query`, `affected`, `path`, `explain`, `god-nodes`, …) — builds the graph *and* answers structural questions, including symbol-level ones. This is the primary surface; it is enough for the whole scoping workflow.
- **MCP server** (`python -m graphify.serve <graph.json>`) — the same graph exposed as in-session tools (`query_graph`, `shortest_path`, `get_node`, `get_neighbors`, `get_community`, `god_nodes`, `graph_stats`). Convenient, not required. Needs the `mcp` extra.

So **"who calls X?" *is* a CLI capability here** (`graphify affected "X"`). No MCP round-trip, no fallback to grep.

## Setup (once per repo)

1. `command -v graphify` — if missing, offer to install it: `pipx install graphifyy` (the PyPI name is `graphifyy` while `graphify` is being reclaimed upstream; the CLI is still `graphify`). See the plugin README for alternatives (`uv tool install`, plain `pip`).
2. Check for an existing graph: `graphify-out/graph.json` in the repo root.
3. Build it:
   - `graphify extract . --code-only` — AST-only pass. Fully local, **no API key**, no model calls. This is the default choice for scoping a codebase.
   - `graphify extract .` — full pass: AST *plus* a semantic LLM pass over docs/PDFs/images. **This one calls an LLM** (`--backend gemini|kimi|claude|openai|deepseek|ollama`, picked from whichever API key is set). Only reach for it when the corpus is genuinely mixed (papers, notes, diagrams) and the user is fine with the calls.
4. Keep it fresh: `graphify update .` re-extracts changed code files with no LLM. `graphify hook install` wires a post-commit hook that does it automatically; `graphify check-update .` reports whether a semantic re-pass is pending.
5. Make sure `graphify-out/` is in the project's `.gitignore` (add it if you create the graph).

**Do not run `graphify install` or `graphify claude install`.** Those install graphify's *own* skill, register it in `~/.claude/CLAUDE.md`, and (for `claude install`) add `PreToolUse` hooks to `.claude/settings.json` — competing instructions that collide with this skill. The bare CLI is all this workflow needs. If the user wants graphify's own skill too, that's their call to make explicitly, not a side effect of scoping a reading list.

### Optional: the MCP server

If a session leans heavily on structural Q&A and the user prefers in-session tools over CLI calls, the graph can be served over MCP. **Recommend it and wait for explicit confirmation** — never rewrite the user's MCP configuration unprompted. Registration is manual (graphify's installers do not register it):

```
uv run --with graphifyy --with mcp -m graphify.serve <repo>/graphify-out/graph.json
```

as the command for an MCP stdio server entry. Once registered, `query_graph`, `shortest_path`, `get_node`, `get_neighbors`, `get_community`, `god_nodes`, and `graph_stats` are available directly. Everything they answer, the CLI also answers — this is ergonomics, not capability.

## Queries to Use

| Question | How |
|---|---|
| Who calls X / what depends on Y? | `graphify affected "X" --depth 2` — reverse traversal from the symbol |
| Reading list for an area | `graphify query "<question>" --budget 2000` — BFS over the graph, token-capped |
| How do A and B connect? | `graphify path "A" "B"` — shortest path between two nodes |
| What is X, and what sits next to it? | `graphify explain "X"` — node plus neighbors, in plain language |
| Architecture overview / where's the core? | `graphify god-nodes --top 10` (hubs); `graphify-out/GRAPH_REPORT.md`; `graphify tree` or `graphify export callflow-html` for a visual |
| What changed and what does it impact? | `graphify update .` then `graphify affected "<changed symbol>"` — there is no diff-scoped subcommand; go from the diff's symbols |
| Graph shape / freshness | `graphify-out/graph.json` mtime; `graphify check-update .`; `graphify benchmark` |

Run these yourself (output is small and token-budgeted) or hand them to the oracle / recon subagent. Every edge is tagged `EXTRACTED`, `INFERRED`, or `AMBIGUOUS` — an `INFERRED` edge is a hypothesis, not a call site, so don't report one as a confirmed caller.

The graph isn't only for the working project — it works on **any repo root**, including an external repo cloned for research. graphify has a helper for exactly that: `graphify clone <github-url>` clones to `~/.graphify/repos/<owner>/<repo>` and prints the path. So the research move is: ask the user → `graphify clone` → `graphify extract <path> --code-only` → scope the oracle's reading list from the graph. That turns "read an unfamiliar repo" into "read these 6 files." Working across several repos at once, `graphify global add <graph.json> --as <tag>` merges them into one cross-repo graph under `~/.graphify/`.

## The Pattern

1. Graph: given a change (the symbols its diff touches) or an area of interest, which symbols and files are in the blast radius? → `graphify affected` / `graphify query` → a concrete file list (typically a handful instead of a directory).
2. Oracle: spawn it with exactly that list to read fully.
3. Structural follow-ups during work ("who calls this?", "what depends on that module?") → the graph CLI (or its MCP tools if registered) — answered in milliseconds, without spawning anything.
4. Semantic follow-ups ("why does this retry twice?", "where is the invariant enforced?") → the live oracle via `SendMessage`.

## Caveats

- **The semantic pass costs LLM calls.** `graphify extract .` dispatches to a configured backend for docs/PDFs/images; `--code-only` avoids that entirely. Don't silently spend the user's API budget to scope a reading list.
- **`INFERRED` / `AMBIGUOUS` edges are guesses.** Only `EXTRACTED` edges come from the AST. Treat the rest as a strong prior, not ground truth — and if the oracle's reading contradicts the graph, trust the read code.
- **No diff-scoped subcommand.** Derive the changed symbols from the diff yourself, then `affected` each one.
- Query output is capped (`--budget`, default 2000 tokens) and shaped as prose. Use `--json` where a command offers it (`god-nodes`); otherwise parse it as prose, don't script against it.
- A stale graph misleads: after big rebases or generated-code churn, `graphify update .` before querying (`--force` after refactors that delete code, else the rebuild is refused for having fewer nodes).
- Language coverage is Tree-sitter based: Python, TS/JS, Go, Rust, Java, C/C++, Ruby, C#, Kotlin, Scala, PHP. Outside that set the graph leans on the semantic pass, which needs an LLM backend.
