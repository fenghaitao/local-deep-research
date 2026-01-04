#!/bin/bash
# Start Local Deep Research with GPU support

echo "Starting Local Deep Research with NVIDIA GPU support..."
docker compose -f docker-compose.yml -f docker-compose.gpu.override.yml up -d

echo ""
echo "Services starting..."
echo "Waiting for services to be ready..."
sleep 5

echo ""
echo "Checking GPU status..."
docker compose logs ollama --tail 20 | grep -E "GPU|CUDA|vram" || echo "GPU logs not available yet"

echo ""
echo "Services are running:"
echo "  - Local Deep Research: http://localhost:5000"
echo "  - SearXNG: http://localhost:8080"
echo "  - Ollama (GPU): http://localhost:11434"
echo ""
echo "To view logs:"
echo "  docker compose logs -f"
echo ""
echo "To stop services:"
echo "  docker compose -f docker-compose.yml -f docker-compose.gpu.override.yml down"
