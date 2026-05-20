# Release Notes Template

```markdown
## vX.Y.Z Release Notes

<1-2 sentence summary of what this release delivers and why.>

### Highlights

- <key change 1>
- <key change 2>
- <key change 3>

---

### What's Changed Since vX.Y.(Z-1)

#### 1) <Category>

<Description of changes in this category.>

#### 2) <Category>

<Description of changes in this category.>

---

### Scope Summary

- Commits since vX.Y.(Z-1): N
- Files changed: N
- Insertions / Deletions: +N / -N

---

### Compatibility Notes

- <breaking change or note, or "No breaking changes.">

---

### Full Compare

https://github.com/<owner>/<repo>/compare/vX.Y.(Z-1)...vX.Y.Z
```

## Notes

- Use only ASCII characters throughout (see ascii-replacements.md).
- The "Scope Summary" numbers come from `git diff <last-tag>..HEAD --stat`.
- The "Full Compare" URL is always the last line.
