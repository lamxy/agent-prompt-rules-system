# ASCII Replacements for Release Notes

When AI-generated text contains Unicode characters that look like ASCII but are not,
replace them before writing to the notes file.

## Common Homoglyphs (look-alike substitutions)

| Character | Name | Codepoint | Replace with |
|-----------|------|-----------|--------------|
| Cyrillic small a | CYRILLIC SMALL LETTER A | U+0430 | `a` |
| Cyrillic small e | CYRILLIC SMALL LETTER IE | U+0435 | `e` |
| Cyrillic small o | CYRILLIC SMALL LETTER O | U+043E | `o` |
| Cyrillic small p | CYRILLIC SMALL LETTER ER | U+0440 | `p` |
| Cyrillic small c | CYRILLIC SMALL LETTER ES | U+0441 | `c` |
| Cyrillic small x | CYRILLIC SMALL LETTER HA | U+0445 | `x` |

## Common Punctuation / Math Symbols

| Character | Name | Codepoint | Replace with |
|-----------|------|-----------|--------------|
| - | MINUS SIGN | U+2212 | `-` |
| -- | EM DASH | U+2014 | `--` |
| - | EN DASH | U+2013 | `-` |
| -> | RIGHTWARDS ARROW | U+2192 | `->` |
| x | MULTIPLICATION SIGN | U+00D7 | `x` |
| (c) | COPYRIGHT SIGN | U+00A9 | `(c)` |
| ... | HORIZONTAL ELLIPSIS | U+2026 | `...` |

## Scripts: Find and Replace Non-ASCII

### Python (cross-platform, preferred)

```python
# detect_and_fix.py -- run as: python3 detect_and_fix.py
import sys

REPLACEMENTS = {
    0x0430: 'a',    # Cyrillic a
    0x0435: 'e',    # Cyrillic e
    0x043E: 'o',    # Cyrillic o
    0x0440: 'p',    # Cyrillic p
    0x0441: 'c',    # Cyrillic c
    0x0445: 'x',    # Cyrillic x
    0x2212: '-',    # Minus sign
    0x2014: '--',   # Em dash
    0x2013: '-',    # En dash
    0x2192: '->',   # Rightwards arrow
    0x00D7: 'x',    # Multiplication sign
    0x2026: '...',  # Horizontal ellipsis
}

path = '.release_notes_tmp.md'
data = open(path, encoding='utf-8').read()

fixed = []
for ch in data:
    cp = ord(ch)
    if cp > 127:
        replacement = REPLACEMENTS.get(cp)
        if replacement:
            print(f'Replaced U+{cp:04X} ({ch!r}) -> {replacement!r}')
            fixed.append(replacement)
        else:
            print(f'WARNING: unknown non-ASCII U+{cp:04X} ({ch!r}), kept as-is', file=sys.stderr)
            fixed.append(ch)
    else:
        fixed.append(ch)

open(path, 'w', encoding='utf-8').write(''.join(fixed))
print('Done.')
```

### Unix shell (detect only)

```sh
# Show line numbers and offending characters
grep -Pn '[^\x00-\x7F]' .release_notes_tmp.md
# Exit code 0 means matches found (problem); exit code 1 means clean
```

### PowerShell (Windows fallback)

```powershell
$f = '.release_notes_tmp.md'
$text = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
$map = @{
    [char]0x0430='a'; [char]0x0435='e'; [char]0x043E='o'
    [char]0x2212='-'; [char]0x2014='--'; [char]0x2013='-'
    [char]0x2192='->'; [char]0x00D7='x'; [char]0x2026='...'
}
foreach ($k in $map.Keys) { $text = $text.Replace([string]$k, $map[$k]) }
[System.IO.File]::WriteAllText($f, $text, [System.Text.Encoding]::UTF8)
```
