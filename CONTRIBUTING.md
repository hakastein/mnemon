# Contributing to Mnemon

Thanks for your interest in improving Mnemon! This is a small, focused plugin —
contributions of all sizes are welcome, from typo fixes to new skill behavior.

## What Mnemon is (and isn't)

Mnemon is a **Claude Code / Codex plugin** made of prompt-engineering assets:
Markdown skills, an agent persona, and JSON manifests. There is no compiled code
and no runtime of its own. That shapes how we work:

- Changes are mostly to `skills/`, `agents/`, `docs/`, and the plugin manifests.
- "Tests" are about whether the skill *triggers and behaves* correctly when an
  agent reads it — there is no unit-test suite to run.
- Keep prose tight. The skill files are loaded into a model's context, so every
  extra sentence costs tokens for every user, forever. Edit for density.

## Ground rules

- **Be kind.** This project follows the [Code of Conduct](CODE_OF_CONDUCT.md).
- **Match the surrounding voice.** Read the file you're editing and mirror its
  tone, structure, and density before adding to it.
- **One logical change per PR.** Smaller PRs get reviewed and merged faster.

## Development workflow

1. **Fork** the repo and create a branch off `main`:
   ```bash
   git checkout -b feat/short-description
   ```
2. **Make your change.** If you touch a skill, re-read the whole skill afterward
   to make sure the change still reads coherently top-to-bottom.
3. **Keep manifests valid and in sync.** If you change the version, bump it in
   every manifest at once:
   ```bash
   ./scripts/bump-version.sh 0.3.0   # sets the version everywhere
   ./scripts/bump-version.sh --check # verifies all manifests agree
   ```
4. **Run the local checks** that CI will run (see below).
5. **Update `CHANGELOG.md`** under an `## Unreleased` heading describing your
   change in user-facing terms.
6. **Open a pull request** against `main`, filling in the PR template.

## Running checks locally

CI validates JSON manifests, version consistency, and Markdown. You can run the
same checks before pushing:

```bash
# JSON manifests parse
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json .codex-plugin/plugin.json; do
  jq empty "$f"
done

# Versions agree across manifests
./scripts/bump-version.sh --check

# Markdown lint (if you have it installed)
npx --yes markdownlint-cli2 "**/*.md"
```

None of these require network access or API keys.

## Commit messages

Keep them short and imperative, matching the existing history:

```
Add SECURITY policy and dependabot config (0.3.0)
```

If your change is generated with AI assistance, that's fine — disclose it in the
PR's environment section so reviewers have full context.

## Reporting bugs and requesting features

Use the [issue templates](https://github.com/hakastein/mnemon/issues/new/choose).
Because Mnemon's behavior depends on the harness and model running it, please
include your environment details (model, harness, versions) — the templates ask
for these.

## Releasing (maintainers)

1. `./scripts/bump-version.sh X.Y.Z`
2. Move `CHANGELOG.md`'s `## Unreleased` section under the new version + date.
3. Commit, merge to `main` via PR, then tag: `git tag vX.Y.Z && git push --tags`.
4. Cut a GitHub Release from the tag, pasting the changelog section.
