#!/bin/bash
# fetch + unpack latest
set -e
: "${GH_TOKEN:?}" "${TASK_KEY:?}" "${REPO:?}"
API="https://api.github.com/repos/$REPO"
RUN="${1:-latest}"
OUT="${2:-out.txt}"
if [ "$RUN" = "latest" ]; then
  RUN=$(curl -fsSL -H "Authorization: Bearer $GH_TOKEN" "$API/actions/runs?per_page=10" | python3 -c 'import sys,json;d=json.load(sys.stdin);r=[x for x in d["workflow_runs"] if x["status"]=="completed"];print(r[0]["id"])')
fi
AID=$(curl -fsSL -H "Authorization: Bearer $GH_TOKEN" "$API/actions/runs/$RUN/artifacts" | python3 -c 'import sys,json;d=json.load(sys.stdin);a=[x for x in d["artifacts"] if x["name"]=="result"];print(a[0]["id"] if a else "")')
[ -n "$AID" ] || { echo "no result artifact for run $RUN"; exit 1; }
curl -fsSL -H "Authorization: Bearer $GH_TOKEN" -o /tmp/r.zip "$API/actions/artifacts/$AID/zip"
rm -rf /tmp/rx; mkdir -p /tmp/rx
unzip -oq /tmp/r.zip -d /tmp/rx
openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass "pass:$TASK_KEY" -in /tmp/rx/result.bin -out "$OUT" 2>/dev/null || { echo "decrypt failed (wrong key?)"; exit 1; }
echo "saved: $OUT ($(wc -l < "$OUT" | tr -d ' ') lines)"
