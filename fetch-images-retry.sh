#!/bin/bash
set -euo pipefail

source .unsplash-credentials
DIR="zdjecia"

# Retry failed ones with simpler queries
PLANTS=(
  "bananowiec|banana plant pot"
  "berberys|barberry bush pot garden"
  "budleja|butterfly bush pot garden"
  "chamaerops|european fan palm pot"
  "cytrusy|lemon tree pot balcony"
  "kostrzewa|blue fescue grass pot"
  "litodora|Lithodora blue flowers garden"
  "mirt|myrtle plant pot garden"
  "oliwka|olive tree potted"
  "ostnica|feather grass ornamental pot"
  "slonecznik|dwarf sunflower pot"
  "szalwia|salvia blue flowers pot"
  "truskawka|strawberry pot balcony"
)

for entry in "${PLANTS[@]}"; do
  slug="${entry%%|*}"
  query="${entry#*|}"

  if [[ -f "$DIR/$slug.jpg" ]]; then
    echo "SKIP $slug (already exists)"
    continue
  fi

  echo -n "FETCH $slug ($query) ... "

  encoded_query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$query'))")
  response=$(curl -s "https://api.unsplash.com/search/photos?query=${encoded_query}&per_page=1&orientation=landscape" \
    -H "Authorization: Client-ID $UNSPLASH_ACCESS_KEY")

  img_url=$(echo "$response" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['results'][0]['urls']['small'])" 2>/dev/null || true)
  dl_url=$(echo "$response" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['results'][0]['links']['download_location'])" 2>/dev/null || true)

  if [[ -z "$img_url" ]]; then
    echo "NO RESULTS"
    continue
  fi

  curl -s "$dl_url" -H "Authorization: Client-ID $UNSPLASH_ACCESS_KEY" > /dev/null &
  curl -s -L "$img_url" -o "$DIR/$slug.jpg"
  echo "OK ($(du -h "$DIR/$slug.jpg" | cut -f1))"

  sleep 0.5
done

echo "Done!"