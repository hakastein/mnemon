---
name: code-oracle
description: Use when researching material outside the current project — a large body of documentation or an external repo.
---

# Code Oracle

An **oracle** is a separate agent that holds external material in its own context and answers your questions about it with citations. The pages stay in its window; only answers reach yours.

External means read-only for you: a product's documentation or API reference, a spec, release notes, another project's source. The current project stays in your own window — even when you only study how it already does something, that reading belongs next to the edit it informs.

## Steps

1. **Name the question** you need answered. It is the finish line for you and the oracle.
2. **Gather the sources**: for documentation — the product, its version, any URL you already have; for a repo — its URL, or the paths of the few files that matter. When the question needs broad reading of a repo, ask the user before downloading it; on yes, clone it and scope the reading list with [graph.md](graph.md).
3. **Start the oracle**: the `mnemon:oracle` agent, briefed with the question and the sources. Where that agent isn't registered, brief a general agent with [the oracle persona](../../agents/oracle.md) as well. Use a mid-tier model; step up only when the material itself needs heavy reasoning. Too much material for one window → one oracle per sub-topic.
4. **Ask follow-ups of the same oracle** — it still holds everything it read; a new one starts from nothing. On a runtime where an agent can't be addressed again, put every question into the first brief.
5. **Done** when the question from step 1 is answered with a citation behind every claim you will act on.
