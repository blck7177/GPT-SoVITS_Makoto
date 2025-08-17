## 从git下载权重
# 进入 workspace 目录
cd /workspace

# 创建 weights 文件夹
mkdir -p /workspace/weights

export GITHUB_TOKEN=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

set -euo pipefail
export OWNER="blck7177"
export REPO="makoto-weights"
export TAG="v1"

mkdir -p /workspace/weights

# 取 release JSON
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/releases/tags/$TAG" \
  -o /tmp/release.json

# 用 Python 解析出想要的 asset id，并发起下载（保留 Authorization 与 octet-stream）
python - <<'PY'
import json, os, subprocess, sys
data = json.load(open("/tmp/release.json"))
want = {
  "ref.wav": "/workspace/weights/ref.wav",
  "ref_neutral_short.wav": "/workspace/weights/ref_neutral_short.wav",
  "makoto_test1-e25.ckpt": "/workspace/weights/makoto_test1-e25.ckpt",
  "makoto_test1_e25_s750.pth": "/workspace/weights/makoto_test1_e25_s750.pth",
}
assets = {a["name"]: a["id"] for a in data.get("assets", [])}

missing = [n for n in want if n not in assets]
if missing:
    print("这些文件在 release 里没找到：", ", ".join(missing))
    sys.exit(1)

for name, outp in want.items():
    aid = assets[name]
    url = f"https://api.github.com/repos/{os.environ['OWNER']}/{os.environ['REPO']}/releases/assets/{aid}"
    cmd = [
        "curl","-L",
        "-H", f"Authorization: token {os.environ['GITHUB_TOKEN']}",
        "-H","Accept: application/octet-stream",
        "-o", outp,
        url,
    ]
    print("Downloading:", name)
    subprocess.check_call(cmd)
PY
