#!/usr/bin/env python3
import json
import os
import time
import urllib.request

host = os.environ.get("NINFER_HOST", "127.0.0.1")
port = os.environ.get("NINFER_PORT", "8080")
model = os.environ.get("NINFER_MODEL_ID", "qwen3.8-27b-ninfer")
api_key = os.environ.get("NINFER_API_KEY", "")
url = f"http://{host}:{port}/v1/chat/completions"
payload = {
    "model": model,
    "messages": [
        {
            "role": "user",
            "content": (
                "Write a detailed technical explanation of how virtual memory "
                "works in Linux. Continue until the token limit."
            ),
        }
    ],
    "max_tokens": 512,
    "temperature": 0.0,
    "stream": False,
}


def run(label: str) -> None:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={
            "Content-Type": "application/json",
            **({"Authorization": f"Bearer {api_key}"} if api_key else {}),
        },
    )
    started = time.perf_counter()
    with urllib.request.urlopen(request, timeout=600) as response:
        result = json.load(response)
    duration = time.perf_counter() - started
    tokens = result["usage"]["completion_tokens"]
    print(
        json.dumps(
            {
                "run": label,
                "seconds": round(duration, 4),
                "completion_tokens": tokens,
                "tokens_per_second": round(tokens / duration, 2),
                "finish_reason": result["choices"][0]["finish_reason"],
            }
        )
    )


run("warmup")
for index in range(1, 4):
    run(f"measured-{index}")
