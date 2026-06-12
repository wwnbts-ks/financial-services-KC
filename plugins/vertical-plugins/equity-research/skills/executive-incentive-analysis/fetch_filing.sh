#!/usr/bin/env bash
# fetch_filing.sh — download one filing through the local proxy and convert to text.
#
# Why this exists: cninfo/HKEXnews PDFs fail on the first naive curl (fake-IP TLS
# errors, missing UA, no retry), and the model used to re-improvise a download+
# pdftotext retry loop every run — 7–18 min of wall-clock per filing. This makes
# the fetch deterministic, proxy-routed, cache-first, and idempotent.
#
# Usage:
#   fetch_filing.sh <ticker> <url> [basename]
#
# Behavior:
#   - Saves <url> to $RESEARCH_CACHE/<ticker>/<basename> (basename inferred from URL).
#   - Cache-first: if the file already exists and is non-empty, skips the download.
#   - If the file is a PDF, also writes <basename>.txt once (pdftotext -layout,
#     falling back to PyMuPDF). The .txt is cached too.
#   - Routes through $FILING_PROXY (default http://127.0.0.1:1082) so cninfo's
#     fake-IP resolution doesn't blow up TLS. Override via env if the port changes.
#
# Exit codes: 0 ok (downloaded or cache hit), non-zero on hard failure. On
# failure the caller should STOP and ask the user to drop the file in the cache
# folder — never fabricate (see SKILL.md "When a Primary Source Can't Be Reached").
set -euo pipefail

PROXY="${FILING_PROXY:-http://127.0.0.1:1082}"
CACHE_ROOT="${RESEARCH_CACHE:-./research-cache}"

ticker="${1:?usage: fetch_filing.sh <ticker> <url> [basename]}"
url="${2:?usage: fetch_filing.sh <ticker> <url> [basename]}"
base="${3:-}"
if [ -z "$base" ]; then
  base="$(basename "${url%%\?*}")"
fi
[ -n "$base" ] || base="filing_$(printf '%s' "$url" | cksum | cut -d' ' -f1).pdf"

dir="$CACHE_ROOT/$ticker"
mkdir -p "$dir"
out="$dir/$base"

# --- download (cache-first) -------------------------------------------------
if [ -s "$out" ]; then
  echo "CACHE_HIT  $out"
else
  echo "DOWNLOAD   $url"
  echo "       ->  $out  (via $PROXY)"
  curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 20 --max-time 180 \
    -x "$PROXY" \
    -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36" \
    -o "$out" "$url"
fi

# --- convert PDF -> text (once) ---------------------------------------------
case "$out" in
  *.pdf|*.PDF)
    txt="${out%.*}.txt"
    if [ -s "$txt" ]; then
      echo "TXT_CACHED $txt"
    elif pdftotext -layout "$out" "$txt" 2>/dev/null && [ -s "$txt" ]; then
      echo "PDFTOTEXT  $txt"
    elif python3 -c 'import fitz' 2>/dev/null; then
      python3 - "$out" "$txt" <<'PYEOF'
import sys, fitz
doc = fitz.open(sys.argv[1])
with open(sys.argv[2], "w") as fh:
    for page in doc:
        fh.write(page.get_text())
print("PYMUPDF   ", sys.argv[2])
PYEOF
    else
      echo "WARN: no pdftotext/pymupdf available — left raw PDF, convert manually" >&2
    fi
    ;;
esac

echo "OK         $out"
