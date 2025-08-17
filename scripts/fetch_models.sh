#!/usr/bin/env bash

# fetch_models.sh  ——  Download GPT-SoVITS v2 ProPlus inference dependencies
#
# 1. Chinese text frontend models (RoBERTa & HuBERT)
# 2. G2PWModel (pinyin → prosody) with multi-mirror fallback
# 3. (Optional) Speaker Verification model
# 4. Generate/overwrite configs/tts_infer.yaml pointing to your custom weights
#
# Usage:
#   bash scripts/fetch_models.sh \
#       --t2s /workspace/weights/makoto_test1-e25.ckpt \
#       --vits /workspace/weights/makoto_test1_e25_s750.pth [--skip-sv]
#
# If --t2s/--vits are omitted they default to the same paths above.
# -----------------------------------------------------------------------------
set -euo pipefail

# ----------------------------- Helper functions ------------------------------
log()  { printf "\033[1;32m[INFO]\033[0m  %s\n"  "$*" ; }
warn() { printf "\033[1;33m[WARN]\033[0m  %s\n"  "$*" ; }
err()  { printf "\033[1;31m[ERR ]\033[0m  %s\n"  "$*" ; exit 1 ; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || err "Required command '$1' not found" ; }

need_cmd python3
need_cmd curl
need_cmd unzip

# Root inside container/repo (assume run from repo root but be safe)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

# Arguments -------------------------------------------------------------------
T2S="/workspace/weights/makoto_test1-e25.ckpt"
VITS="/workspace/weights/makoto_test1_e25_s750.pth"
SKIP_SV=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --t2s)  T2S="$2"; shift 2;;
    --vits) VITS="$2"; shift 2;;
    --skip-sv) SKIP_SV=true; shift;;
    *) err "Unknown arg: $1";;
  esac
done

# Ensure directories ----------------------------------------------------------
mkdir -p GPT_SoVITS/pretrained_models \
         GPT_SoVITS/pretrained_models/v2Pro \
         GPT_SoVITS/text

# Install huggingface_hub if missing -----------------------------------------
python3 - <<'PY'
import importlib, subprocess, sys
try:
    importlib.import_module('huggingface_hub')
except ImportError:
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '--upgrade', 'huggingface_hub'])
PY

# --------------------- 1. Chinese frontend (RoBERTa + HuBERT) ---------------
python3 - <<'PY'
import os, shutil, sys
from huggingface_hub import snapshot_download

DST_ROOT = 'GPT_SoVITS/pretrained_models'
frontends = ['chinese-roberta-wwm-ext-large', 'chinese-hubert-base']
missing = []
for name in frontends:
    chk = os.path.join(DST_ROOT, name, 'pytorch_model.bin')
    if not os.path.exists(chk):
        missing.append(name)
if not missing:
    print('Chinese frontend already present, skip download.')
    sys.exit(0)

print('Downloading Chinese frontend models:', ', '.join(missing))
_tmp = snapshot_download(
    repo_id='lj1995/GPT-SoVITS',
    allow_patterns=[f'{m}/*' for m in missing]
)

for name in missing:
    src = os.path.join(_tmp, name)
    dst = os.path.join(DST_ROOT, name)
    if os.path.exists(dst):
        shutil.rmtree(dst)
    shutil.copytree(src, dst)
print('✓ Chinese frontend ready under', DST_ROOT)
PY

# --------------------- 2. G2PWModel (multi-mirror fallback) ------------------
G2P_DST="GPT_SoVITS/text/G2PWModel"
if [[ -f "$G2P_DST/g2pW.onnx" ]]; then
  log "G2PWModel already present, skip download."
else
  log "Downloading G2PWModel…"
  mkdir -p /tmp/G2PW && rm -rf /tmp/G2PW/*
  URLS=(
    "https://paddlespeech.cdn.bcebos.com/Parakeet/released_models/g2p/G2PWModel_1.1.zip"
    "https://huggingface.co/XXXXRT/GPT-SoVITS-Pretrained/resolve/main/G2PWModel.zip"
    "https://www.modelscope.cn/models/XXXXRT/GPT-SoVITS-Pretrained/resolve/master/G2PWModel.zip"
  )
  ok=0
  for u in "${URLS[@]}"; do
    log "Trying $u"
    if curl -L --fail -o /tmp/G2PW.zip "$u"; then
      unzip -q /tmp/G2PW.zip -d /tmp/G2PW || continue
      F=$(find /tmp/G2PW -type f -name 'g2pW.onnx' | head -n1 || true)
      if [[ -n "$F" ]]; then
        rm -rf "$G2P_DST"
        mkdir -p "$(dirname "$G2P_DST")"
        mv "$(dirname "$F")" "$G2P_DST"
        ok=1; break
      fi
    fi
  done
  [[ $ok -eq 1 ]] || err "All mirrors failed for G2PWModel"
  log "✓ G2PWModel ready: $G2P_DST"
fi

# --------------------- 3. Speaker Verification model (optional) -------------
if ! $SKIP_SV; then
  SV_DST="GPT_SoVITS/pretrained_models/sv/pretrained_eres2netv2w24s4ep4.ckpt"
  if [[ -f "$SV_DST" ]]; then
    log "SV model already present, skip download."
  else
    python3 - <<'PY'
import os, shutil, sys
from huggingface_hub import hf_hub_download
outp = 'GPT_SoVITS/pretrained_models/sv/pretrained_eres2netv2w24s4ep4.ckpt'
os.makedirs(os.path.dirname(outp), exist_ok=True)
try:
    p = hf_hub_download('lj1995/GPT-SoVITS', 'sv/pretrained_eres2netv2w24s4ep4.ckpt')
    shutil.copy(p, outp)
    print('✓ SV model downloaded.')
except Exception as e:
    print('⚠  SV model download failed:', e)
PY
  fi
else
  warn "Skip SV model as requested."
fi

# --------------------- 4. Generate configs/tts_infer.yaml -------------------
YAML_PATH="configs/tts_infer.yaml"
cat > "$YAML_PATH" <<YAML
custom:
  bert_base_path: GPT_SoVITS/pretrained_models/chinese-roberta-wwm-ext-large
  cnhuhbert_base_path: GPT_SoVITS/pretrained_models/chinese-hubert-base
  device: cuda
  is_half: true
  t2s_weights_path: $T2S
  vits_weights_path: $VITS
  version: v2ProPlus
YAML
log "✓ Wrote $YAML_PATH"

log "All models ready. You can now run: python api_v2.py -a 0.0.0.0 -p 9880 -c $YAML_PATH"
