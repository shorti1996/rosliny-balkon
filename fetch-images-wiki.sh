#!/bin/bash
set -euo pipefail

DIR="zdjecia"

# slug|Wikipedia article title
PLANTS=(
  "bananowiec|Musa_acuminata"
  "berberys|Berberis_thunbergii"
  "budleja|Buddleja_davidii"
  "chamaerops|Chamaerops_humilis"
  "cytrusy|Citrus"
  "kostrzewa|Festuca_glauca"
  "litodora|Lithodora_diffusa"
  "mirt|Myrtus_communis"
  "oliwka|Olea_europaea"
  "ostnica|Stipa_tenuissima"
  "slonecznik|Helianthus_annuus"
  "szalwia|Salvia_farinacea"
  "truskawka|Fragaria"
)

for entry in "${PLANTS[@]}"; do
  slug="${entry%%|*}"
  wiki="${entry#*|}"

  if [[ -f "$DIR/$slug.jpg" ]]; then
    echo "SKIP $slug (already exists)"
    continue
  fi

  echo -n "FETCH $slug ($wiki) ... "

  img_url=$(curl -s "https://en.wikipedia.org/api/rest_v1/page/summary/$wiki" | \
    python3 -c "
import json,sys
d=json.load(sys.stdin)
if 'thumbnail' in d:
    # Get a 400px wide version
    src = d['originalimage']['source']
    # Construct a thumbnail URL at 400px
    parts = src.rsplit('/', 1)
    thumb = parts[0].replace('/commons/', '/commons/thumb/') + '/' + parts[1] + '/400px-' + parts[1]
    print(thumb)
" 2>/dev/null || true)

  if [[ -z "$img_url" ]]; then
    echo "NO IMAGE"
    continue
  fi

  http_code=$(curl -s -L -o "$DIR/$slug.jpg" -w "%{http_code}" "$img_url")
  if [[ "$http_code" == "200" ]]; then
    echo "OK ($(du -h "$DIR/$slug.jpg" | cut -f1))"
  else
    rm -f "$DIR/$slug.jpg"
    echo "FAILED ($http_code)"
  fi

  sleep 0.3
done

echo "Done!"