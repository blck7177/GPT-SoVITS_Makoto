#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# download_release_weights.sh
# ----------------------------------------------------------------------------
# Download selected assets from a GitHub release (private or public) into
#   /workspace/weights
#
# Environment variable required:
#   GITHUB_TOKEN   – Personal Access Token with `repo` scope (for private repos
#                    or to avoid rate-limit)
#
# Optional flags:
#   --owner <owner>   (default: blck7177)
#   --repo  <repo>    (default: makoto-weights)
#   --tag   <tag>     (default: v1)
# ----------------------------------------------------------------------------
set -euo pipefail

OWNER="blck7177"
REPO="makoto-weights"
TAG="v1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2;;
    --repo)  REPO="$2";  shift 2;;
    --tag)   TAG="$2";   shift 2;;
    -h|--help)
      echo "Usage: bash $0 [--owner USER] [--repo REPO] [--tag TAG]"; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 1;;
  esac
done

: "${GITHUB_TOKEN?ERROR: GITHUB_TOKEN environment variable not set}"

dest_dir="/workspace/weights"
mkdir -p "$dest_dir"

api_url="https://api.github.com/repos/$OWNER/$REPO/releases/tags/$TAG"
echo "[INFO] Fetching release metadata from $api_url"
curl -sSL -H "Authorization: token $GITHUB_TOKEN" "$api_url" -o /tmp/release.json

# Desired assets & destination filenames -------------------------------------
python3 - <<'PY'
import json, os, subprocess, sys, textwrap, pathlib

# Desired assets mapping ------------------------------------------------------
want = {
    "ref.wav": "/workspace/weights/ref.wav",
    "ref_neutral_short.wav": "/workspace/weights/ref_neutral_short.wav",
    "makoto_test1-e25.ckpt": "/workspace/weights/makoto_test1-e25.ckpt",
    "makoto_test1_e25_s750.pth": "/workspace/weights/makoto_test1_e25_s750.pth",
}

with open("/tmp/release.json", "r", encoding="utf-8") as f:
    data = json.load(f)
assets = {a["name"]: a["id"] for a in data.get("assets", [])}

missing = [n for n in want if n not in assets]
if missing:
    print("[ERROR] Assets not found in release:", ", ".join(missing), file=sys.stderr)
    sys.exit(1)

for name, outp in want.items():
    if pathlib.Path(outp).exists():
        print(f"[SKIP] {name} already exists → {outp}")
        continue
    aid = assets[name]
    url = f"https://api.github.com/repos/{os.environ['OWNER']}/{os.environ['REPO']}/releases/assets/{aid}"
    cmd = [
        "curl", "-L",
        "-H", f"Authorization: token {os.environ['GITHUB_TOKEN']}",
        "-H", "Accept: application/octet-stream",
        "-o", outp,
        url,
    ]
    print(f"[INFO] Downloading {name} → {outp}")
    subprocess.check_call(cmd)
print("[DONE] All requested assets downloaded.")
PY
