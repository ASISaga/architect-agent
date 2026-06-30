# Issue Template

## Format

```markdown
## What

One paragraph. What needs to change and why.

## Acceptance criteria

- [ ] Specific, testable criterion
- [ ] Another criterion
- [ ] Tests pass

## Spec references

- `.github/specs/{spec-name}.md` — {what section is relevant}

## Copilot prompt

```
Implement {what} in {repo} according to `.github/specs/{spec-name}.md`.

Specifically:
- {concrete action 1}
- {concrete action 2}

Acceptance criteria:
- {criterion 1}
- {criterion 2}

Run `pytest tests/ -q` and confirm all tests pass before opening the PR.
```
```

## Rules

- Single consolidated issue per concern
- Acceptance criteria are testable, not vague
- Copilot prompt is at the bottom, fenced
- Spec reference is a path, not a description
- One issue per PR — do not bundle unrelated changes
