#!/usr/bin/env bash
set -euo pipefail

cd /workspace/your-gptsovits || exit 1

if [ -f .env ]; then
  set -a; source .env; set +a
fi

TEXT="${1:-你好呀，今天想聊点什么？}"
OUT="${2:-out.wav}"
APP_PORT=${APP_PORT:-9880}

curl -s -X POST "http://127.0.0.1:${APP_PORT}/tts" \
  -H "Content-Type: application/json" \
  --data "{\
    \"text\": \"${TEXT}\",\
    \"text_lang\": \"${TEXT_LANG:-zh}\",\
    \"ref_audio_path\": \"${REF_AUDIO:-/workspace/weights/ref.wav}\",\
    \"prompt_text\": \"参考音频文本\",\
    \"prompt_lang\": \"${PROMPT_LANG:-zh}\",\
    \"text_split_method\": \"${TEXT_SPLIT_METHOD:-cut5}\",\
    \"batch_size\": ${BATCH_SIZE:-1},\
    \"streaming_mode\": false,\
    \"media_type\": \"${MEDIA_TYPE:-wav}\",\
    \"top_k\": ${TOP_K:-5},\
    \"top_p\": ${TOP_P:-1.0},\
    \"temperature\": ${TEMPERATURE:-1.0},\
    \"repetition_penalty\": ${REPETITION_PENALTY:-1.35},\
    \"speed_factor\": ${SPEED:-1.0}\
  }" \
  --output "${OUT}"

echo "Saved -> ${OUT}"
