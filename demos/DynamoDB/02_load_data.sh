#!/usr/bin/env bash
set -euo pipefail

TABLE_NAME="Music"
REGION="us-east-1"

echo "=== Loading song data into $TABLE_NAME ==="

aws dynamodb batch-write-item --region "$REGION" --request-items '{
  "Music": [
    {"PutRequest":{"Item":{"Artist":{"S":"The Beatles"},"SongTitle":{"S":"Hey Jude"},"Album":{"S":"Non-album single"},"Year":{"N":"1968"},"Genre":{"S":"Rock"}}}},
    {"PutRequest":{"Item":{"Artist":{"S":"The Beatles"},"SongTitle":{"S":"Let It Be"},"Album":{"S":"Let It Be"},"Year":{"N":"1970"},"Genre":{"S":"Rock"}}}},
    {"PutRequest":{"Item":{"Artist":{"S":"The Beatles"},"SongTitle":{"S":"Come Together"},"Album":{"S":"Abbey Road"},"Year":{"N":"1969"},"Genre":{"S":"Rock"}}}},
    {"PutRequest":{"Item":{"Artist":{"S":"Prince"},"SongTitle":{"S":"Purple Rain"},"Album":{"S":"Purple Rain"},"Year":{"N":"1984"},"Genre":{"S":"Pop/Rock"}}}},
    {"PutRequest":{"Item":{"Artist":{"S":"Prince"},"SongTitle":{"S":"When Doves Cry"},"Album":{"S":"Purple Rain"},"Year":{"N":"1984"},"Genre":{"S":"Pop"}}}},
    {"PutRequest":{"Item":{"Artist":{"S":"Stevie Wonder"},"SongTitle":{"S":"Superstition"},"Album":{"S":"Talking Book"},"Year":{"N":"1972"},"Genre":{"S":"Funk/Soul"}}}},
    {"PutRequest":{"Item":{"Artist":{"S":"Stevie Wonder"},"SongTitle":{"S":"Signed Sealed Delivered"},"Album":{"S":"Signed Sealed and Delivered"},"Year":{"N":"1970"},"Genre":{"S":"Soul"}}}},
    {"PutRequest":{"Item":{"Artist":{"S":"Aretha Franklin"},"SongTitle":{"S":"Respect"},"Album":{"S":"I Never Loved a Man"},"Year":{"N":"1967"},"Genre":{"S":"Soul"}}}},
    {"PutRequest":{"Item":{"Artist":{"S":"Aretha Franklin"},"SongTitle":{"S":"Natural Woman"},"Album":{"S":"Lady Soul"},"Year":{"N":"1968"},"Genre":{"S":"Soul"}}}},
    {"PutRequest":{"Item":{"Artist":{"S":"David Bowie"},"SongTitle":{"S":"Heroes"},"Album":{"S":"Heroes"},"Year":{"N":"1977"},"Genre":{"S":"Art Rock"}}}}
  ]
}'

echo ""
echo "=== Loaded 10 items ==="
