#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_FILE="$PROJECT_DIR/data/tirukkural.json"

echo "============================================"
echo "  Loading Thirukkural Dataset"
echo "============================================"
echo ""

# Check OpenSearch is running
if ! curl -s "http://localhost:9200" > /dev/null; then
    echo "ERROR: OpenSearch is not running. Run ./scripts/setup.sh first."
    exit 1
fi

# Function to create index and load data
create_and_load() {
    local INDEX_NAME=$1
    local SETTINGS=$2

    echo "Creating index: $INDEX_NAME"

    # Delete if exists
    curl -s -X DELETE "http://localhost:9200/$INDEX_NAME" 2>/dev/null || true

    # Create index
    curl -s -X PUT "http://localhost:9200/$INDEX_NAME" \
        -H 'Content-Type: application/json' \
        -d "$SETTINGS" > /dev/null

    # Load data
    python3 << PYEOF
import json
import requests

with open("$DATA_FILE", "r", encoding="utf-8") as f:
    kurals = json.load(f)

bulk_data = ""
for kural in kurals:
    bulk_data += json.dumps({"index": {"_index": "$INDEX_NAME", "_id": kural["kural_number"]}}) + "\n"
    bulk_data += json.dumps(kural, ensure_ascii=False) + "\n"

response = requests.post(
    "http://localhost:9200/_bulk",
    headers={"Content-Type": "application/json"},
    data=bulk_data.encode("utf-8")
)

result = response.json()
if result.get("errors"):
    print("  Errors occurred during indexing")
else:
    print(f"  Loaded {len(kurals)} kurals")
PYEOF
}

echo ""
echo "[1/4] Creating tirukkural_standard (default analyzer)..."
create_and_load "tirukkural_standard" '{
  "mappings": {
    "properties": {
      "kural_number": { "type": "integer" },
      "chapter": { "type": "keyword" },
      "tamil_text": { "type": "text" },
      "transliteration": { "type": "text" },
      "meaning_en": { "type": "text" }
    }
  }
}'

echo ""
echo "[2/4] Creating tirukkural_icu (ICU tokenizer only)..."
create_and_load "tirukkural_icu" '{
  "settings": {
    "analysis": {
      "analyzer": {
        "tamil_icu": {
          "type": "custom",
          "tokenizer": "icu_tokenizer",
          "char_filter": ["icu_normalizer"],
          "filter": ["lowercase"]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "kural_number": { "type": "integer" },
      "chapter": { "type": "keyword" },
      "tamil_text": { "type": "text", "analyzer": "tamil_icu" },
      "transliteration": { "type": "text" },
      "meaning_en": { "type": "text" }
    }
  }
}'

echo ""
echo "[3/4] Creating tirukkural_icu_custom (ICU + stemming filter)..."
create_and_load "tirukkural_icu_custom" '{
  "settings": {
    "analysis": {
      "char_filter": {
        "tamil_nfc": {
          "type": "icu_normalizer",
          "name": "nfc",
          "mode": "compose"
        }
      },
      "filter": {
        "tamil_stop": {
          "type": "stop",
          "stopwords_path": "analysis/tamil_stop.txt"
        },
        "tamil_stem": {
          "type": "pattern_replace",
          "pattern": "(க்கு|இல்|களின்|கள்|இன்|ஆல்|டையார்|டைமை|இலார்|ற்கு|த்து|ன்று|ுள்ள|ான|ின்|ும்)$",
          "replacement": ""
        }
      },
      "analyzer": {
        "tamil_icu_custom": {
          "type": "custom",
          "tokenizer": "icu_tokenizer",
          "char_filter": ["tamil_nfc"],
          "filter": ["lowercase", "tamil_stop", "tamil_stem"]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "kural_number": { "type": "integer" },
      "chapter": { "type": "keyword" },
      "tamil_text": { "type": "text", "analyzer": "tamil_icu_custom" },
      "transliteration": { "type": "text" },
      "meaning_en": { "type": "text" }
    }
  }
}'

echo ""
echo "[4/4] Creating tirukkural_tamil (analysis-tamil plugin)..."
create_and_load "tirukkural_tamil" '{
  "settings": {
    "analysis": {
      "analyzer": {
        "tamil_analyzer": {
          "type": "tamil"
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "kural_number": { "type": "integer" },
      "chapter": { "type": "keyword" },
      "tamil_text": { "type": "text", "analyzer": "tamil_analyzer" },
      "transliteration": { "type": "text" },
      "meaning_en": { "type": "text" }
    }
  }
}'

echo ""
echo "Refreshing indices..."
curl -s -X POST "http://localhost:9200/_refresh" > /dev/null

echo ""
echo "============================================"
echo "  Data Loading Complete!"
echo "============================================"
echo ""
curl -s "http://localhost:9200/_cat/indices/tirukkural*?v&s=index"
echo ""
