#!/bin/bash

echo "============================================"
echo "  Tamil Analysis Comparison Tests"
echo "============================================"
echo ""

# Function to search and count hits
search_count() {
    local INDEX=$1
    local QUERY=$2
    local COUNT=$(curl -s -X GET "http://localhost:9200/$INDEX/_search" \
        -H 'Content-Type: application/json' \
        -d "{\"query\": {\"match\": {\"tamil_text\": \"$QUERY\"}}, \"size\": 0}" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['hits']['total']['value'])")
    echo "$COUNT"
}

# Function to analyze text
analyze() {
    local INDEX=$1
    local TEXT=$2
    curl -s -X POST "http://localhost:9200/$INDEX/_analyze" \
        -H 'Content-Type: application/json' \
        -d "{\"field\": \"tamil_text\", \"text\": \"$TEXT\"}" \
        | python3 -c "import sys,json; print([t['token'] for t in json.load(sys.stdin)['tokens']])"
}

echo "============================================"
echo "  TEST 1: Analyzer Output Comparison"
echo "============================================"
echo ""
echo "Input: அன்புடையார் (one who has love)"
echo ""
printf "%-25s %s\n" "Analyzer" "Tokens"
printf "%-25s %s\n" "--------" "------"
printf "%-25s %s\n" "standard" "$(analyze tirukkural_standard 'அன்புடையார்')"
printf "%-25s %s\n" "icu" "$(analyze tirukkural_icu 'அன்புடையார்')"
printf "%-25s %s\n" "icu_custom" "$(analyze tirukkural_icu_custom 'அன்புடையார்')"
printf "%-25s %s\n" "tamil (plugin)" "$(analyze tirukkural_tamil 'அன்புடையார்')"

echo ""
echo "Input: வீட்டில் (in the house)"
echo ""
printf "%-25s %s\n" "Analyzer" "Tokens"
printf "%-25s %s\n" "--------" "------"
printf "%-25s %s\n" "standard" "$(analyze tirukkural_standard 'வீட்டில்')"
printf "%-25s %s\n" "icu" "$(analyze tirukkural_icu 'வீட்டில்')"
printf "%-25s %s\n" "icu_custom" "$(analyze tirukkural_icu_custom 'வீட்டில்')"
printf "%-25s %s\n" "tamil (plugin)" "$(analyze tirukkural_tamil 'வீட்டில்')"

echo ""
echo "Input: மரங்கள் (trees)"
echo ""
printf "%-25s %s\n" "Analyzer" "Tokens"
printf "%-25s %s\n" "--------" "------"
printf "%-25s %s\n" "standard" "$(analyze tirukkural_standard 'மரங்கள்')"
printf "%-25s %s\n" "icu" "$(analyze tirukkural_icu 'மரங்கள்')"
printf "%-25s %s\n" "icu_custom" "$(analyze tirukkural_icu_custom 'மரங்கள்')"
printf "%-25s %s\n" "tamil (plugin)" "$(analyze tirukkural_tamil 'மரங்கள்')"

echo ""
echo "============================================"
echo "  TEST 2: Search Results Comparison"
echo "============================================"
echo ""
echo "Search query: அன்பு (love)"
echo ""
printf "%-25s %s\n" "Index" "Hits"
printf "%-25s %s\n" "-----" "----"
printf "%-25s %s\n" "tirukkural_standard" "$(search_count tirukkural_standard 'அன்பு')"
printf "%-25s %s\n" "tirukkural_icu" "$(search_count tirukkural_icu 'அன்பு')"
printf "%-25s %s\n" "tirukkural_icu_custom" "$(search_count tirukkural_icu_custom 'அன்பு')"
printf "%-25s %s\n" "tirukkural_tamil" "$(search_count tirukkural_tamil 'அன்பு')"

echo ""
echo "Search query: வீடு (house)"
echo ""
printf "%-25s %s\n" "Index" "Hits"
printf "%-25s %s\n" "-----" "----"
printf "%-25s %s\n" "tirukkural_standard" "$(search_count tirukkural_standard 'வீடு')"
printf "%-25s %s\n" "tirukkural_icu" "$(search_count tirukkural_icu 'வீடு')"
printf "%-25s %s\n" "tirukkural_icu_custom" "$(search_count tirukkural_icu_custom 'வீடு')"
printf "%-25s %s\n" "tirukkural_tamil" "$(search_count tirukkural_tamil 'வீடு')"

echo ""
echo "Search query: கல்வி (education)"
echo ""
printf "%-25s %s\n" "Index" "Hits"
printf "%-25s %s\n" "-----" "----"
printf "%-25s %s\n" "tirukkural_standard" "$(search_count tirukkural_standard 'கல்வி')"
printf "%-25s %s\n" "tirukkural_icu" "$(search_count tirukkural_icu 'கல்வி')"
printf "%-25s %s\n" "tirukkural_icu_custom" "$(search_count tirukkural_icu_custom 'கல்வி')"
printf "%-25s %s\n" "tirukkural_tamil" "$(search_count tirukkural_tamil 'கல்வி')"

echo ""
echo "============================================"
echo "  TEST 3: Matching Kurals for 'அன்பு'"
echo "============================================"
echo ""

curl -s -X GET "http://localhost:9200/tirukkural_tamil/_search" \
    -H 'Content-Type: application/json' \
    -d '{"query": {"match": {"tamil_text": "அன்பு"}}, "_source": ["kural_number", "tamil_text", "chapter"]}' \
    | python3 -c "
import sys, json
r = json.load(sys.stdin)
for hit in r['hits']['hits']:
    src = hit['_source']
    print(f\"Kural {src['kural_number']} ({src['chapter']}):\")
    print(f\"  {src['tamil_text']}\")
    print()
"

echo "============================================"
echo "  Summary"
echo "============================================"
echo ""
echo "The analysis-tamil plugin outperforms other analyzers because:"
echo ""
echo "1. SUFFIX STRIPPING: Removes Tamil case markers, plurals, and"
echo "   postpositions (e.g., பள்ளிக்கு → பள்ளி)"
echo ""
echo "2. SANDHI NORMALIZATION: Reverses morphophonemic changes"
echo "   (e.g., வீட்டில் → வீடு, மரங்கள் → மரம்)"
echo ""
echo "3. STOPWORD REMOVAL: Filters common Tamil words like நான், நீ, etc."
echo ""
echo "4. POSSESSIVE HANDLING: Stems forms like அன்புடையார் → அன்பு"
echo ""
