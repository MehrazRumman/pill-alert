"""Fails if any string reaching context.tr()/trIn() has no Hindi or Spanish translation.

English is the message key (see lib/i18n/translations.dart), so a missing entry is silent at
runtime — the string simply stays English. This makes that visible. Run: python3 tool/check_translations.py
"""
import re, sys, pathlib

def split_top(body):
    parts, cur, depth, q, i = [], '', 0, None, 0
    while i < len(body):
        ch = body[i]
        if q:
            cur += ch
            if ch == '\\': cur += body[i+1]; i += 2; continue
            if ch == q: q = None
            i += 1; continue
        if ch in "'\"": q = ch; cur += ch; i += 1; continue
        if ch in '([{': depth += 1
        elif ch in ')]}': depth -= 1
        elif ch == ',' and depth == 0:
            parts.append(cur); cur = ''; i += 1; continue
        cur += ch; i += 1
    parts.append(cur)
    return parts

def literal_text(src):
    raw = ''.join(a or b for a, b in
                  re.findall(r"'((?:[^'\\]|\\.)*)'|\"((?:[^\"\\]|\\.)*)\"", src))
    # Dart escapes survive the regex; the map keys hold the unescaped text.
    return (raw.replace("\\'", "'").replace('\\"', '"')
               .replace('\\n', '\n').replace('\\$', '$').replace('\\\\', '\\'))

def table(name):
    src = pathlib.Path('lib/i18n/translations.dart').read_text()
    block = src.split(f'Map<String, String> {name} = <String, String>{{')[1].split('\n  };')[0]
    return set(literal_text(m.group(0)) for m in re.finditer(r'"(?:[^"\\]|\\.)*":', block))

hi, es = table('hi'), table('es')
missing = []
for p in sorted(pathlib.Path('lib').rglob('*.dart')):
    if p.name == 'translations.dart': continue
    t = p.read_text()
    for m in re.finditer(r'\b(?:context\.tr|trIn)\(', t):
        i, d, st = m.end(), 1, m.end()
        while i < len(t) and d:
            if t[i] == '(': d += 1
            elif t[i] == ')': d -= 1
            i += 1
        body = t[st:i-1]
        parts = split_top(body)
        named = ' '.join(parts[2:])
        offset = 1 if m.group(0).startswith('trIn') else 0
        if len(parts) < 2 + offset: continue
        en_src = parts[1 + offset]
        if '$' in en_src: continue          # interpolated: needs explicit hi:/es:
        en = literal_text(en_src)
        if not en: continue
        line = t[:m.start()].count('\n') + 1
        if 'hi:' not in named and en not in hi: missing.append((p, line, 'hi', en))
        if 'es:' not in named and en not in es: missing.append((p, line, 'es', en))

for p, line, lang, en in missing:
    print(f'{p}:{line}  missing {lang}: {en!r}')
print(f'\n{len(missing)} untranslated string(s)')
sys.exit(1 if missing else 0)
