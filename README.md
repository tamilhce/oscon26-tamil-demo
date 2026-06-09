# Tamil Language Analysis for OpenSearch

> Demo repository for OSCON 2026 talk on Tamil language analysis with OpenSearch.

This repository demonstrates how to build and use a custom Tamil language analysis plugin for OpenSearch. It includes the complete setup to run OpenSearch 3.6.0 locally with the `analysis-tamil` plugin, load the Thirukkural dataset (1330 ancient Tamil verses), and compare search results across different analyzer configurations.

## Why This Plugin?

### The Problem with Default Analyzers

Tamil is a morphologically rich, agglutinative language where words are formed by combining roots with multiple suffixes. A single root can have hundreds of inflected forms:

| Root | Meaning | Inflected Forms |
|------|---------|-----------------|
| வீடு | house | வீட்டில் (in house), வீட்டுக்கு (to house), வீடுகள் (houses), வீடுகளில் (in houses)... |
| அன்பு | love | அன்புடையார் (one who has love), அன்புடைமை (having love), அன்பிலார் (one without love)... |

**Standard OpenSearch analyzers fail** because they treat each inflected form as a separate token. Searching for "வீடு" won't find documents containing "வீட்டில்" even though they refer to the same concept.

### What This Plugin Does

The `analysis-tamil` plugin provides:

1. **Suffix Stripping** - Removes 100+ Tamil grammatical suffixes (case markers, plurals, postpositions, verb tenses)
2. **Sandhi Normalization** - Reverses morphophonemic sound changes that occur when morphemes combine
3. **Stopword Filtering** - Removes common Tamil function words (pronouns, conjunctions, particles)
4. **Possessive Handling** - Stems complex forms like அன்புடையார் → அன்பு

### The Gap It Addresses

| Feature | Standard | ICU | analysis-tamil |
|---------|----------|-----|----------------|
| Unicode tokenization | Basic | Good | Good |
| Tamil stopwords | No | No | Yes |
| Suffix stripping | No | No | Yes |
| Sandhi normalization | No | No | Yes |
| "அன்பு" finds "அன்புடையார்" | No | No | **Yes** |
| "வீடு" finds "வீட்டில்" | No | No | **Yes** |

## End-to-End Installation Guide

### Prerequisites

- Docker and Docker Compose
- curl
- Python 3 with `requests` library (`pip install requests`)
- 4GB+ RAM available for Docker

### Quick Start

```bash
# Clone this repository
git clone https://github.com/tamilhce/oscon26-tamil-demo.git
cd oscon26-tamil-demo

# Make scripts executable
chmod +x scripts/*.sh

# Build and start OpenSearch with plugins
./scripts/setup.sh

# Load Thirukkural dataset into 4 indices
./scripts/load_data.sh

# Run comparison tests
./scripts/test_search.sh
```

### What Gets Installed

The setup script builds a custom Docker image with:
- OpenSearch 3.6.0
- analysis-icu plugin (for Unicode normalization)
- analysis-tamil plugin (custom Tamil stemmer)
- OpenSearch Dashboards 3.0.0

### Accessing the Services

| Service | URL |
|---------|-----|
| OpenSearch API | http://localhost:9200 |
| OpenSearch Dashboards | http://localhost:5601 |

### Manual Installation (Without Docker)

1. Download OpenSearch 3.6.0 from [opensearch.org](https://opensearch.org/downloads.html)

2. Install the ICU plugin:
```bash
bin/opensearch-plugin install analysis-icu
```

3. Install the Tamil plugin:
```bash
bin/opensearch-plugin install file:///path/to/plugins/analysis-tamil-3.6.0.zip
```

4. Start OpenSearch:
```bash
bin/opensearch
```

## Testing with Thirukkural Dataset

The Thirukkural is a classic Tamil text containing 1330 couplets (kurals) on ethics, politics, and love. It's an ideal test dataset because it uses classical Tamil with rich morphological variation.

### Dataset Format

```json
{
  "kural_number": 1,
  "chapter": "கடவுள் வாழ்த்து",
  "tamil_text": "அகர முதல எழுத்தெல்லாம் ஆதி பகவன் முதற்றே உலகு.",
  "transliteration": "Akara mudhala ezhuthellaam aadhi bhagavan mudhatre ulagu.",
  "meaning_en": "A, as its first of letters, every speech maintains; The Primal Deity is first through all the world's domains."
}
```

### Four Index Configurations

The `load_data.sh` script creates four indices with different analyzers:

| Index | Analyzer | Description |
|-------|----------|-------------|
| `tirukkural_standard` | Default | No stemming, exact match only |
| `tirukkural_icu` | ICU tokenizer | Better Unicode handling, no stemming |
| `tirukkural_icu_custom` | ICU + char_filter | Basic suffix removal via regex |
| `tirukkural_tamil` | analysis-tamil | Full stemming + sandhi + stopwords |

### Dev Tools Queries

Open Dashboards at http://localhost:5601 → Dev Tools, then try:

```json
# Compare how each analyzer tokenizes "அன்புடையார்"

POST /tirukkural_standard/_analyze
{ "field": "tamil_text", "text": "அன்புடையார்" }
// Result: ["அன்புடையார்"]

POST /tirukkural_icu/_analyze
{ "field": "tamil_text", "text": "அன்புடையார்" }
// Result: ["அன்புடையார்"]

POST /tirukkural_tamil/_analyze
{ "field": "tamil_text", "text": "அன்புடையார்" }
// Result: ["அன்பு"]  <-- Stemmed!
```

```json
# Search for "அன்பு" (love) across all indices

GET /tirukkural_standard/_search
{ "query": { "match": { "tamil_text": "அன்பு" } } }
// Hits: 0

GET /tirukkural_tamil/_search
{ "query": { "match": { "tamil_text": "அன்பு" } } }
// Hits: 4 (finds அன்புடையார், அன்புடைமை, அன்பிலார்)
```

```json
# Compare all indices at once

GET /tirukkural_standard,tirukkural_icu,tirukkural_icu_custom,tirukkural_tamil/_search
{
  "query": { "match": { "tamil_text": "அன்பு" } },
  "size": 0,
  "aggs": { "by_index": { "terms": { "field": "_index" } } }
}
```

```json
# Test sandhi normalization: "வீடு" finding "வீட்டில்"

POST /tirukkural_tamil/_analyze
{ "field": "tamil_text", "text": "வீட்டில்" }
// Result: ["வீடு"]  <-- Sandhi normalized!

POST /tirukkural_tamil/_analyze
{ "field": "tamil_text", "text": "மரங்கள்" }
// Result: ["மரம்"]  <-- Consonant insertion reversed!
```

### Search Results Comparison

| Search Query | standard | icu | icu_custom | **tamil** |
|--------------|----------|-----|------------|-----------|
| அன்பு (love) | 0 | 0 | 3 | **4** |
| வீடு (house) | 1 | 1 | 1 | **3** |
| கல்வி (education) | 8 | 8 | 8 | **12** |

The `analysis-tamil` plugin consistently finds more relevant results by matching morphological variants.

## How It Works

### Analysis Pipeline

```
Input: "நான் பள்ளிக்கு போனேன்" (I went to school)
                ↓
┌─────────────────────────────────────┐
│  StandardTokenizer                  │
│  → ["நான்", "பள்ளிக்கு", "போனேன்"]    │
└─────────────────────────────────────┘
                ↓
┌─────────────────────────────────────┐
│  StopFilter (tamil_stop)            │
│  → ["பள்ளிக்கு", "போனேன்"]            │  (நான் removed)
└─────────────────────────────────────┘
                ↓
┌─────────────────────────────────────┐
│  TamilStemmer                       │
│  1. Suffix strip: க்கு removed      │
│  2. Sandhi normalize: none needed   │
│  → ["பள்ளி", "போனேன்"]               │
└─────────────────────────────────────┘
```

### Sandhi Normalization

Tamil sandhi (புணர்ச்சி) causes sound changes when morphemes combine:

```
வீடு + இல் = வீட்டில்  (ட doubles)
மரம் + கள் = மரங்கள்  (ம் becomes ங்)
```

The stemmer reverses these changes after suffix stripping:

| Input | After Suffix Strip | After Sandhi | Rule |
|-------|-------------------|--------------|------|
| வீட்டில் | வீட்ட | வீடு | ட்ட → டு |
| மரங்கள் | மரங் | மரம் | ங் → ம் |
| நாட்டில் | நாட்ட | நாடு | ட்ட → டு |

### Code Structure

```
analysis-tamil/
├── src/main/java/.../tamil/
│   ├── AnalysisTamilPlugin.java      # Plugin entry point
│   ├── TamilAnalyzer.java            # Pre-built "tamil" analyzer
│   ├── TamilStemmer.java             # Core stemming + sandhi logic
│   ├── TamilStemTokenFilterFactory.java
│   ├── TamilStopTokenFilterFactory.java
│   └── TamilStopWords.java
│
└── src/main/resources/.../tamil/
    ├── tamil_suffixes.txt            # 100+ suffixes
    ├── tamil_prefixes.txt            # Prefixes (disabled by default)
    └── tamil_sandhi.txt              # Sandhi lookup table
```

### Configuration Options

```json
{
  "filter": {
    "my_tamil_stemmer": {
      "type": "tamil_stemmer",
      "min_stem_length": 2,      // Minimum stem length
      "strip_prefixes": false,   // Prefix stripping (default: off)
      "strip_suffixes": true,    // Suffix stripping (default: on)
      "apply_sandhi": true       // Sandhi normalization (default: on)
    }
  }
}
```

### Upstream PR

This plugin is being contributed to the OpenSearch project:
- Repository: https://github.com/tamilhce/OpenSearch
- Branch: `feature/analysis-tamil`

## References

### Tamil Linguistics
- [Tamil Sandhi Rules Explained](https://www.sariya.app/learn/sandhi-rules-explained) - Comprehensive guide to Tamil morphophonemic changes
- [Tamil Grammar - Wikipedia](https://en.wikipedia.org/wiki/Tamil_grammar) - Overview of Tamil morphology
- [Thirukkural - Wikipedia](https://en.wikipedia.org/wiki/Tirukku%E1%B9%9Fa%E1%B8%B7) - About the classic Tamil text

### OpenSearch
- [OpenSearch Analysis Documentation](https://opensearch.org/docs/latest/analyzers/)
- [Custom Analyzers](https://opensearch.org/docs/latest/analyzers/custom-analyzers/)
- [ICU Analysis Plugin](https://opensearch.org/docs/latest/analyzers/icu-plugin/)

### Related Projects
- [Elasticsearch ICU Plugin](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-icu.html)
- [Lucene Analyzers](https://lucene.apache.org/core/9_0_0/analysis/common/index.html)

## Cleanup

To stop and remove all containers:

```bash
./scripts/cleanup.sh
```

## License

Apache License 2.0

## Author

Presented at OSCON 2026
