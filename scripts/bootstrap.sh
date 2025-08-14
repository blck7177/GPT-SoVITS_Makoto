#!/usr/bin/env bash
set -euxo pipefail

# Install system packages (if base image lacks them)
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ffmpeg libsox-dev git

# 项目根目录
cd /workspace/GPT-SoVITS_Makoto || exit 1

# Python virtual environment
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip

# Install upstream dependencies
# cd GPT-SoVITS
pip install -r extra-req.txt --no-deps
pip install -r requirements.txt

# Ensure weight directories exist
mkdir -p /workspace/weights
mkdir -p GPT_SoVITS/pretrained_models

echo "Bootstrap finished. Activate venv with: source /workspace/GPT-SoVITS_Makoto/.venv/bin/activate"
