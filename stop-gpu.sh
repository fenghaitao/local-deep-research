#!/bin/bash
# Stop Local Deep Research services (GPU mode)

echo "Stopping Local Deep Research services..."
docker compose -f docker-compose.yml -f docker-compose.gpu.override.yml down

echo ""
echo "Services stopped."
