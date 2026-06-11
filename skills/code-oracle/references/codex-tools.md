# Codex tool mapping

The `code-oracle` skill is authored in Claude Code tool names. On [Codex CLI](https://developers.openai.com/codex/cli) use these equivalents — the skill body is **not** rewritten, you just read tool names through this table.

| Skill reference | Codex equivalent |
|---|---|
| `Agent` / `Task` (spawn the oracle subagent) | `spawn_agent` — requires multi-agent support enabled (see below) |
| `subagent_type: mnemon:oracle` | The oracle persona is supplied by the skill's prompt template. Optionally define a reusable agent at `~/.codex/agents/oracle.toml` (`name`, `description`, `developer_instructions` = the persona body) and spawn that. |
| `SendMessage(to: agentId)` — follow-up to the **live** oracle (Mode B) | Re-prompt / steer the *same running* agent thread; `/agent` switches between and inspects active threads. **Keep the thread open** — do NOT `close_agent` until the area is done. This open, re-queryable thread is what makes the live oracle work on Codex. |
| Task returns its result | `wait_agent` |
| Freeing a finished oracle | `close_agent` |
| `Read` / `Grep` / `Glob` / `Bash` | Your native file and shell tools |
| `WebFetch` / `WebSearch` | Your native web/fetch tools |
| `Skill` (invoke `code-oracle`) | Skills load natively — just follow the instructions |
| `code-review-graph` CLI | Unchanged — it's an external CLI (`pipx install code-review-graph`) and runs identically under any agent |

## Subagent dispatch requires multi-agent support

`spawn_agent` / `wait_agent` / `close_agent` are only available when multi-agent mode is on. Add to `~/.codex/config.toml`:

```toml
[features]
multi_agent = true
```

Legacy note: Codex before `rust-v0.115.0` exposed waiting as `wait`; current Codex uses `wait_agent` (bare `wait` now means code-mode `exec`/`wait` by `cell_id`).

## The persistent-oracle caveat

Mode B (the live oracle you keep asking) depends on a subagent thread that stays addressable across follow-ups. Codex provides this via steerable agent threads, so Mode B works — as long as you don't `close_agent` the oracle between questions. If you are on a runtime that can only spawn-run-once (no re-queryable thread), don't fake it: fall back to one richer **Mode A** recon pass, or read the needed slice yourself. This is the same honest-degradation rule the skill states for Claude runtimes without `SendMessage`.
