# Dev Tools Queries

Copy these queries into OpenSearch Dashboards → Dev Tools (http://localhost:5601/app/dev_tools)

## List All Indices

```json
GET /_cat/indices/tirukkural*?v&s=index
```

## Analyzer Comparison

### Test Standard Analyzer
```json
POST /tirukkural_standard/_analyze
{
  "field": "tamil_text",
  "text": "அன்புடையார்"
}
```

### Test ICU Analyzer
```json
POST /tirukkural_icu/_analyze
{
  "field": "tamil_text",
  "text": "அன்புடையார்"
}
```

### Test ICU Custom Analyzer
```json
POST /tirukkural_icu_custom/_analyze
{
  "field": "tamil_text",
  "text": "அன்புடையார்"
}
```

### Test Tamil Plugin Analyzer
```json
POST /tirukkural_tamil/_analyze
{
  "field": "tamil_text",
  "text": "அன்புடையார்"
}
```

## Sandhi Normalization Tests

### வீட்டில் → வீடு (consonant doubling)
```json
POST /tirukkural_tamil/_analyze
{
  "field": "tamil_text",
  "text": "வீட்டில்"
}
```

### மரங்கள் → மரம் (consonant insertion)
```json
POST /tirukkural_tamil/_analyze
{
  "field": "tamil_text",
  "text": "மரங்கள்"
}
```

### நாட்டில் → நாடு (consonant doubling)
```json
POST /tirukkural_tamil/_analyze
{
  "field": "tamil_text",
  "text": "நாட்டில்"
}
```

## Search Queries

### Search for அன்பு (love)
```json
GET /tirukkural_tamil/_search
{
  "query": {
    "match": {
      "tamil_text": "அன்பு"
    }
  }
}
```

### Search for கல்வி (education)
```json
GET /tirukkural_tamil/_search
{
  "query": {
    "match": {
      "tamil_text": "கல்வி"
    }
  }
}
```

### Search for அறம் (virtue)
```json
GET /tirukkural_tamil/_search
{
  "query": {
    "match": {
      "tamil_text": "அறம்"
    }
  }
}
```

### Search with Highlighting
```json
GET /tirukkural_tamil/_search
{
  "query": {
    "match": {
      "tamil_text": "அன்பு"
    }
  },
  "highlight": {
    "fields": {
      "tamil_text": {}
    }
  }
}
```

## Cross-Index Comparison

### Compare Search Results Across All Indices
```json
GET /tirukkural_standard,tirukkural_icu,tirukkural_icu_custom,tirukkural_tamil/_search
{
  "query": {
    "match": {
      "tamil_text": "அன்பு"
    }
  },
  "size": 0,
  "aggs": {
    "by_index": {
      "terms": {
        "field": "_index"
      }
    }
  }
}
```

### Compare வீடு Search
```json
GET /tirukkural_standard,tirukkural_icu,tirukkural_icu_custom,tirukkural_tamil/_search
{
  "query": {
    "match": {
      "tamil_text": "வீடு"
    }
  },
  "size": 0,
  "aggs": {
    "by_index": {
      "terms": {
        "field": "_index"
      }
    }
  }
}
```

## Index Settings & Mappings

### View Standard Index Settings
```json
GET /tirukkural_standard/_settings
```

### View Tamil Index Settings
```json
GET /tirukkural_tamil/_settings
```

### View Mappings
```json
GET /tirukkural_tamil/_mapping
```

## Specific Kural Lookup

### Get Kural #1
```json
GET /tirukkural_tamil/_doc/1
```

### Search by Chapter
```json
GET /tirukkural_tamil/_search
{
  "query": {
    "term": {
      "chapter": "அன்புடைமை"
    }
  }
}
```

### Search English Meaning
```json
GET /tirukkural_tamil/_search
{
  "query": {
    "match": {
      "meaning_en": "love"
    }
  }
}
```

## Document Count
```json
GET /tirukkural_tamil/_count
```

## Installed Plugins
```json
GET /_cat/plugins?v
```
