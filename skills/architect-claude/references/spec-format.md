# Spec Format Reference

Specs live in `.github/specs/` in the relevant repository.

## Structure

```markdown
# {Spec Title}

**Specification for:** `ASISaga/{repo}`
**Path:** `.github/specs/{spec-name}.md`
**Version:** 1.0.0

---

## What This Spec Covers

One paragraph. Precise scope.

---

## {Main sections}

Implementation requirements, interfaces, data structures.
Actionable — a Copilot agent should be able to implement from this.

---

## Invariants

What must never change. Why.

---

## Related Specifications

| Spec | Relationship |
|---|---|
| `other-spec.md` | Why it's related |
```

## Rules

- No Copilot-specific syntax — specs are Copilot-agnostic
- Under 300 lines in the main file
- Move long reference material to `references/` subdirectory
- Every invariant has a reason, not just a rule
- Implementation requirements are precise enough to act on
