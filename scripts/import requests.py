import requests
from urllib.parse import quote

PROXY_URL = "https://hlka9p8zmtkaft-9874.proxy.runpod.net"
params = {
    "text": "你好，我是一次快速测试。",
    "text_lang": "zh",
    "ref_audio_path": "/workspace/weights/ref.wav",
    "prompt_text": "参考音频的简要文字",
    "prompt_lang": "zh",
    "text_split_method": "cut5",
    "batch_size": "1",
    "media_type": "wav",
    "streaming_mode": "false",
}
url = f"{PROXY_URL}/tts"
r = requests.get(url, params=params, timeout=300)
r.raise_for_status()
with open("out_9874.wav", "wb") as f:
    f.write(r.content)
print("Saved to out_9874.wav")