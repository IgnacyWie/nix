import sys, unicodedata

DIAC = set("ąćęłńóśźżĄĆĘŁŃÓŚŹŻ")

def fold(w):
    # map Polish letters to ASCII, then strip any remaining accents
    table = str.maketrans("ąćęłńóśźżĄĆĘŁŃÓŚŹŻ", "acelnoszzACELNOSZZ")
    w = w.translate(table)
    w = unicodedata.normalize("NFKD", w)
    return "".join(c for c in w if not unicodedata.combining(c))

MIN_FREQ = 5
groups = {}  # folded_lower -> dict(form -> freq)
with open("pl_full.txt", encoding="utf-8") as f:
    for line in f:
        parts = line.split()
        if len(parts) != 2:
            continue
        word, freq = parts[0], parts[1]
        try:
            freq = int(freq)
        except ValueError:
            continue
        if freq < MIN_FREQ:
            continue
        # only lowercase alphabetic Polish words
        if not word.isalpha():
            continue
        wl = word.lower()
        folded = fold(wl)
        if not folded.isascii() or not folded.isalpha():
            continue
        g = groups.setdefault(folded, {})
        g[wl] = g.get(wl, 0) + freq

out = []
for folded, forms in groups.items():
    # winner = highest-frequency form
    winner = max(forms.items(), key=lambda kv: kv[1])[0]
    if winner == folded:
        continue  # plain ASCII already the most common -> no replacement
    # only emit if winner actually carries a Polish diacritic
    if not any(ch in DIAC for ch in winner):
        continue
    out.append((folded, winner))

out.sort()
with open("spolszcz-words.tsv", "w", encoding="utf-8") as f:
    for folded, winner in out:
        f.write(f"{folded}\t{winner}\n")

print("entries:", len(out))
