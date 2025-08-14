#!/usr/bin/env bash
set -euo pipefail

cd /workspace/GPT-SoVITS_Makoto || exit 1
source .venv/bin/activate

# Load variables
if [ -f .env ]; then
  set -a; source .env; set +a
fi

APP_PORT=${APP_PORT:-9880}

cd GPT-SoVITS || exit 1

# Launch API (v2) in background
nohup /workspace/GPT-SoVITS_Makoto/.venv/bin/python api_v2.py \
  -a 0.0.0.0 -p "${APP_PORT}" -c /workspace/GPT-SoVITS_Makoto/configs/tts_infer.yaml \
  > /workspace/gptsovits_api.log 2>&1 &

# Wait for service
echo "Waiting for API on :${APP_PORT} ..."
for i in {1..60}; do
  if curl -sf "http://127.0.0.1:${APP_PORT}/docs" >/dev/null; then
    echo "API is up."
    break
  fi
  sleep 1
done

# Automatically set weights
if [ -n "${S1_WEIGHTS:-}" ]; then
  echo "Setting GPT weights: ${S1_WEIGHTS}"
  curl -s "http://127.0.0.1:${APP_PORT}/set_gpt_weights" --get --data-urlencode "weights_path=${S1_WEIGHTS}" >/dev/null || true
fi
if [ -n "${S2_WEIGHTS:-}" ]; then
  echo "Setting SoVITS weights: ${S2_WEIGHTS}"
  curl -s "http://127.0.0.1:${APP_PORT}/set_sovits_weights" --get --data-urlencode "weights_path=${S2_WEIGHTS}" >/dev/null || true
fi

echo "API ready on port ${APP_PORT}. Logs at /workspace/gptsovits_api.log"
