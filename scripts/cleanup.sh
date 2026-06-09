#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Stopping and removing containers..."
cd "$PROJECT_DIR"
docker compose down -v

echo ""
echo "Cleanup complete!"
