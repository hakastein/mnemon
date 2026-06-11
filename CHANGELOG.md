# Changelog

## 0.1.1 — 2026-06-11

- code-review-graph promoted from "optional accelerator" to strongly recommended companion: dedicated install section in the README (pipx/uv/pip), and the skill now offers to install it when missing instead of silently falling back to manual scoping.

## 0.1.0 — 2026-06-11

Initial release.

- `code-oracle` skill: live-oracle and one-shot-recon modes, decision graph, prompt templates, red-flag list.
- `oracle` plugin agent: full-file reading persona with `file:line` citations, read-only tool surface.
- Optional [code-review-graph](https://github.com/tirth8205/code-review-graph) integration for graph-assisted reading-list scoping (`skills/code-oracle/graph.md`).
- Self-marketplace distribution (`/plugin marketplace add hakastein/mnemon`).
