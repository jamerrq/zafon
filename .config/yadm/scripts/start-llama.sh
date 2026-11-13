#!/bin/bash
# Start llama.cpp server with Vulkan GPU acceleration
# Usage: ./start-llama.sh [model-name]
# Models: qwen3.5-4b (default), qwen3-8b

set -euo pipefail

MODELS_DIR="$HOME/.local/share/llama.cpp/models"

case "${1:-qwen3.5-4b}" in
  qwen3.5-4b|qwen35)
    MODEL="$MODELS_DIR/Qwen3.5-4B-Q4_K_M.gguf"
    ;;
  qwen3-8b|qwen3)
    MODEL="$MODELS_DIR/Qwen3-8B-Q4_K_M.gguf"
    ;;
  *)
    echo "Usage: $0 [qwen3.5-4b|qwen3-8b]"
    echo "  qwen3.5-4b  - Qwen3.5 4B (faster, ~2.6GB)"
    echo "  qwen3-8b    - Qwen3 8B (smarter, ~4.7GB)"
    exit 1
    ;;
esac

if [[ ! -f "$MODEL" ]]; then
  echo "Error: Model not found: $MODEL"
  exit 1
fi

echo "Starting llama-server with Vulkan GPU acceleration..."
echo "Model: $MODEL"
echo "API: http://127.0.0.1:8080 (OpenAI-compatible)"
echo "Press Ctrl+C to stop"
echo ""

exec llama-server \
  -m "$MODEL" \
  --host 127.0.0.1 \
  --port 8080 \
  -ngl 99 \
  --flash-attn on \
  --ctx-size 16384 \
  --parallel 4 \
  --log-disable
