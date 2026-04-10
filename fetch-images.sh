#!/bin/bash
set -euo pipefail

source .unsplash-credentials
DIR="zdjecia"
mkdir -p "$DIR"

# slug|search query
PLANTS=(
  "aksamitka|Tagetes plant pot garden"
  "argyranthemum|Argyranthemum plant pot garden"
  "armeria|Armeria maritima plant pot garden"
  "bananowiec|Musa banana plant pot balcony"
  "berberys|Berberis thunbergii plant pot garden"
  "brzoskwinia-karlowa|dwarf peach tree pot garden"
  "budleja|Buddleja davidii plant pot garden"
  "bugenwilla|Bougainvillea plant pot garden"
  "celosia|Celosia plant pot garden"
  "chamaerops|Chamaerops humilis palm pot garden"
  "cytrusy|citrus tree pot garden"
  "euryops|Euryops daisy plant pot garden"
  "gozdzik|Dianthus plant pot garden"
  "hibiskus-syryjski|Hibiscus syriacus plant pot garden"
  "hibiskus-tropikalny|Hibiscus rosa-sinensis plant pot garden"
  "kaktusy|cactus collection pot garden"
  "kostrzewa|Festuca blue grass pot garden"
  "lawenda-anouk|Lavandula stoechas pot garden"
  "litodora|Lithodora diffusa plant pot garden"
  "mirt|Myrtus communis plant pot garden"
  "oliwka|olive tree pot garden"
  "osteospermum|Osteospermum african daisy pot garden"
  "ostnica|Stipa ornamental grass pot garden"
  "ostrokrzew|Ilex holly plant pot garden"
  "petunia|Petunia plant pot garden"
  "rozmaryn|rosemary plant pot garden"
  "sedum|Sedum succulent pot garden"
  "slonecznik|sunflower pot garden"
  "szalwia|Salvia farinacea plant pot garden"
  "truskawka|strawberry plant pot garden"
)

for entry in "${PLANTS[@]}"; do
  slug="${entry%%|*}"
  query="${entry#*|}"

  if [[ -f "$DIR/$slug.jpg" ]]; then
    echo "SKIP $slug (already exists)"
    continue
  fi

  echo -n "FETCH $slug ... "

  # Search
  encoded_query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$query'))")
  response=$(curl -s "https://api.unsplash.com/search/photos?query=${encoded_query}&per_page=1&orientation=landscape" \
    -H "Authorization: Client-ID $UNSPLASH_ACCESS_KEY")

  img_url=$(echo "$response" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['results'][0]['urls']['small'])" 2>/dev/null || true)
  dl_url=$(echo "$response" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['results'][0]['links']['download_location'])" 2>/dev/null || true)

  if [[ -z "$img_url" ]]; then
    echo "NO RESULTS"
    continue
  fi

  # Trigger download tracking (Unsplash requirement)
  curl -s "$dl_url" -H "Authorization: Client-ID $UNSPLASH_ACCESS_KEY" > /dev/null &

  # Download image
  curl -s -L "$img_url" -o "$DIR/$slug.jpg"
  echo "OK ($(du -h "$DIR/$slug.jpg" | cut -f1))"

  # Rate limit: be nice to the API
  sleep 0.5
done

echo "Done!"