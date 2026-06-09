#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "============================================"
echo "  Tamil Analysis Demo - Setup Script"
echo "============================================"
echo ""

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "ERROR: docker is required but not installed."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required but not installed."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 is required but not installed."; exit 1; }

cd "$PROJECT_DIR"

echo "[1/4] Building Docker image with Tamil and ICU plugins..."
docker compose build

echo ""
echo "[2/4] Starting OpenSearch and Dashboards..."
docker compose up -d

echo ""
echo "[3/4] Waiting for OpenSearch to be ready..."
until curl -s "http://localhost:9200/_cluster/health" | grep -q '"status":"green"\|"status":"yellow"'; do
    echo "  Waiting for OpenSearch..."
    sleep 5
done
echo "  OpenSearch is ready!"

echo ""
echo "[4/4] Verifying plugins are installed..."
curl -s "http://localhost:9200/_cat/plugins" | grep -E "analysis-icu|analysis-tamil"

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "  OpenSearch:  http://localhost:9200"
echo "  Dashboards:  http://localhost:5601"
echo ""
echo "  Next steps:"
echo "    ./scripts/load_data.sh    # Load Thirukkural dataset"
echo "    ./scripts/test_search.sh  # Run comparison tests"
echo ""
