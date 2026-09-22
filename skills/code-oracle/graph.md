# Scoping a cloned repo with graphify

[graphify](https://github.com/Graphify-Labs/graphify) builds a structural graph of a repo — symbols, imports, call sites — and turns "read an unfamiliar codebase" into a short reading list for the oracle.

1. Check that `graphify` is on the PATH. Missing → offer to install it (PyPI package `graphifyy`). Declined → give the oracle the clone path alone.
2. Clone: `graphify clone <github-url>` puts the repo under `~/.graphify/repos/<owner>/<repo>` and prints the path. If the oracle can only read inside the project tree, clone into `.refs/<name>` there.
3. Build the graph: `graphify extract <path> --code-only` (local, no API key). Add `--no-gitignore` when the repo has a `.graphifyignore`.
4. Get the reading list: `graphify query "<question>" --budget 2000`, and pass it to the oracle with the clone path.

Structural questions during the research go to the graph directly:

| Question | Command |
|---|---|
| Who calls X / what depends on it | `graphify affected "X" --depth 2` |
| How A and B connect | `graphify path "A" "B"` |
| What X is and what sits next to it | `graphify explain "X"` |
| Where the core of the repo is | `graphify god-nodes --top 10` |

Only `EXTRACTED` edges come from the AST; an `INFERRED` or `AMBIGUOUS` edge is a lead to confirm in the code.

Use the bare CLI: `graphify install` and `graphify claude install` register graphify's own competing skill and hooks, and a full `extract` without `--code-only` spends the user's API key on an LLM pass.
