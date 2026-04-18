#!/bin/bash
# agent-ready-scan.sh — 掃描網站的 Agent-Ready 等級
# 用法：./agent-ready-scan.sh https://your-domain.com

set -e
URL="${1:-}"

if [ -z "$URL" ]; then
  echo "用法：$0 <url>"
  echo "範例：$0 https://example.com"
  exit 1
fi

if ! command -v curl >/dev/null; then echo "需要 curl"; exit 1; fi
if ! command -v python3 >/dev/null; then echo "需要 python3"; exit 1; fi

echo "🔍 掃描：$URL"
echo ""

curl -s -X POST "https://isitagentready.com/api/scan" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"$URL\"}" | python3 <<'PYEOF'
import json, sys
r = json.load(sys.stdin)
print(f"🏆 等級：Level {r['level']} - {r['levelName']}")
print()

total = passed = failed = neutral = 0
for cat, checks in r['checks'].items():
    for name, c in checks.items():
        total += 1
        s = c.get('status')
        if s == 'pass': passed += 1
        elif s == 'fail': failed += 1
        elif s == 'neutral': neutral += 1

print(f"📊 通過：{passed}/{total}  失敗：{failed}  N/A：{neutral}")
print()

for cat, checks in r['checks'].items():
    print(f"【{cat}】")
    for name, c in checks.items():
        mk = {'pass':'✅','fail':'❌','neutral':'⚪'}.get(c.get('status','?'), '?')
        print(f"  {mk} {name}: {c.get('message','')[:80]}")
    print()

if r.get('nextLevel'):
    nl = r['nextLevel']
    print(f"⬆️  升 Level {nl['target']} - {nl['name']} 還差：")
    for req in nl.get('requirements', []):
        print(f"  • {req['check']}")
        print(f"    {req.get('shortPrompt', '')[:120]}")
PYEOF
