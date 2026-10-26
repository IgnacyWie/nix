#!/usr/bin/env python3
"""spolszcz - restore Polish diacritics in text typed on a keyboard without them.

Reads UTF-8 text on stdin, writes the diacritised text to stdout.

The approach is offline and dictionary-based: every alphabetic token is folded
to its bare-ASCII form and looked up in a frequency-built table that maps each
folded form to the most common real Polish word that folds to it (e.g.
"czesc" -> "cześć", "pozniej" -> "później"). Tokens with no diacritic-bearing
winner - including words that are already most common without diacritics, like
"los" or "pan" - are left untouched. Original casing is preserved.

The lookup table is unigram (one word at a time), so genuinely ambiguous words
whose correct form depends on sentence context are resolved to the statistically
more common spelling rather than the context-correct one. That is the accepted
trade-off for a fully offline tool.
"""

import os
import re
import sys
import unicodedata

# Resolve the dictionary next to this script unless overridden.
DEFAULT_DICT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "words.tsv")
DICT_PATH = os.environ.get("SPOLSZCZ_DICT", DEFAULT_DICT)

_FOLD_TABLE = str.maketrans("ąćęłńóśźżĄĆĘŁŃÓŚŹŻ", "acelnoszzACELNOSZZ")

# Runs of letters (any alphabet), so punctuation/whitespace/digits pass through.
_TOKEN_RE = re.compile(r"[^\W\d_]+", re.UNICODE)


def fold(word: str) -> str:
    """Lowercase ASCII-folded key for a word (Polish letters -> bare Latin)."""
    word = word.translate(_FOLD_TABLE)
    word = unicodedata.normalize("NFKD", word)
    return "".join(c for c in word if not unicodedata.combining(c)).lower()


def load_dict(path: str) -> dict:
    table = {}
    try:
        with open(path, encoding="utf-8") as handle:
            for line in handle:
                folded, _, winner = line.rstrip("\n").partition("\t")
                if folded and winner:
                    table[folded] = winner
    except OSError as exc:
        print(f"spolszcz: cannot read dictionary {path}: {exc}", file=sys.stderr)
        sys.exit(1)
    return table


def match_case(source: str, target: str) -> str:
    """Re-apply source's casing shape (lower / Title / UPPER) to target."""
    if source.isupper() and len(source) > 1:
        return target.upper()
    if source[:1].isupper():
        return target[:1].upper() + target[1:]
    return target


def restore(text: str, table: dict) -> str:
    def replace(match: "re.Match") -> str:
        token = match.group(0)
        winner = table.get(fold(token))
        if winner is None:
            return token
        return match_case(token, winner)

    return _TOKEN_RE.sub(replace, text)


def main() -> None:
    table = load_dict(DICT_PATH)
    text = sys.stdin.read()
    sys.stdout.write(restore(text, table))


if __name__ == "__main__":
    main()
