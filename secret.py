import base64, json, os, urllib.request
import nacl.public, nacl.encoding

tok = os.environ["TOKEN"]
repo = os.environ["REPO"]
val = os.environ["TASK_KEY"]

def api(path, method="GET", body=None):
    req = urllib.request.Request("https://api.github.com" + path, method=method)
    req.add_header("Authorization", "Bearer " + tok)
    req.add_header("Accept", "application/vnd.github+json")
    data = json.dumps(body).encode() if body is not None else None
    if data:
        req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, data=data) as r:
        return r.status, r.read()

st, raw = api(f"/repos/{repo}/actions/secrets/public-key")
pk = json.loads(raw)
box = nacl.public.SealedBox(nacl.public.PublicKey(pk["key"], encoder=nacl.encoding.Base64Encoder))
enc = box.encrypt(val.encode())
st2, raw2 = api(f"/repos/{repo}/actions/secrets/TASK_KEY", "PUT",
                {"encrypted_value": base64.b64encode(enc).decode(), "key_id": pk["key_id"]})
print("secret:", st2)
