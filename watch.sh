#!/bin/bash
# poll run, fetch + decrypt on completion
set -e
API="https://api.github.com/repos/$REPO"
RUN_ID="$1"
OUT="$2"
st=queued
for i in $(seq 1 300); do
  st=$(curl -fsSL -H "Authorization: Bearer $TOKEN" "$API/actions/runs/$RUN_ID" | python3 -c 'import sys,json;print(json.load(sys.stdin)["status"])' 2>/dev/null || echo unknown)
  [ "$st" = "completed" ] && break
  sleep 60
done
concl=$(curl -fsSL -H "Authorization: Bearer $TOKEN" "$API/actions/runs/$RUN_ID" | python3 -c 'import sys,json;print(json.load(sys.stdin)["conclusion"])' 2>/dev/null || echo unknown)
echo "run: $st conclusion: $concl"
AID=$(curl -fsSL -H "Authorization: Bearer $TOKEN" "$API/actions/runs/$RUN_ID/artifacts" | python3 -c 'import sys,json;d=json.load(sys.stdin);a=[x for x in d["artifacts"] if x["name"]=="result"];print(a[0]["id"] if a else "")' 2>/dev/null || echo "")
if [ -n "$AID" ]; then
  curl -fsSL -H "Authorization: Bearer $TOKEN" -o /tmp/rz.zip "$API/actions/artifacts/$AID/zip"
  rm -rf /tmp/rz && mkdir -p /tmp/rz && unzip -oq /tmp/rz.zip -d /tmp/rz
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass "pass:$TASK_KEY" -in /tmp/rz/result.bin -out "$OUT" 2>/dev/null || true
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass "pass:$TASK_KEY" -in /tmp/rz/stats.bin -out /tmp/stats.txt 2>/dev/null || true
  echo "lines: $(wc -l < "$OUT" 2>/dev/null | tr -d ' ')"
  echo "nacos: $(grep -c '|nacos' "$OUT" 2>/dev/null || true)"
  echo "--- per shard ---"
  sort /tmp/stats.txt 2>/dev/null || true
else
  echo "no result artifact"
fi
