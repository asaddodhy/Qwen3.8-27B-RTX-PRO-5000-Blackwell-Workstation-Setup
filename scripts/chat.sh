#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"

PROMPT=${*:-Hello}
PROMPT_JSON=$(printf '%s' "$PROMPT" | "$RUNTIME_DIR/bin/python" -c 'import json,sys; print(json.dumps(sys.stdin.read()))')

curl --fail --silent --show-error "$BASE_URL/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer ${API_KEY:-EMPTY}" \
  -d "{
    \"model\": \"$SERVED_MODEL_NAME\",
    \"messages\": [{\"role\": \"user\", \"content\": $PROMPT_JSON}],
    \"max_tokens\": 512,
    \"temperature\": 0.7,
    \"chat_template_kwargs\": {\"enable_thinking\": false}
  }" | "$RUNTIME_DIR/bin/python" -c \
  'import json,sys; print(json.load(sys.stdin)["choices"][0]["message"]["content"])'
