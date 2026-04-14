#!/usr/bin/env bash
# verify-aeo.sh — AEO readiness checker for any website
# Usage: bash verify-aeo.sh https://your-domain.com
# Output: Score 0-100 + recommendations

set -euo pipefail

URL="${1:-}"
if [[ -z "$URL" ]]; then
  echo "Usage: bash verify-aeo.sh <url>"
  echo "Example: bash verify-aeo.sh https://example.com"
  exit 1
fi

# Normalize URL (strip trailing slash)
URL="${URL%/}"
DOMAIN=$(echo "$URL" | sed -E 's|https?://([^/]+).*|\1|')

SCORE=0
PASS=0
FAIL=0
WARNINGS=()
PASSES=()
FAILS=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

check() {
  local label="$1"
  local result="$2"
  local points="$3"
  local recommendation="${4:-}"

  if [[ "$result" == "pass" ]]; then
    SCORE=$((SCORE + points))
    PASS=$((PASS + 1))
    PASSES+=("  ${GREEN}✓${RESET} [+${points}] ${label}")
  else
    FAIL=$((FAIL + 1))
    FAILS+=("  ${RED}✗${RESET} [ 0] ${label}")
    if [[ -n "$recommendation" ]]; then
      WARNINGS+=("    ${YELLOW}→${RESET} ${recommendation}")
    fi
  fi
}

fetch_url() {
  curl -sL --max-time 10 --user-agent "AEO-Verify/1.0" "$1" 2>/dev/null
}

fetch_status() {
  curl -sLo /dev/null -w "%{http_code}" --max-time 10 --user-agent "AEO-Verify/1.0" "$1" 2>/dev/null
}

echo ""
echo -e "${BOLD}AEO Readiness Check${RESET}"
echo -e "Target: ${BLUE}${URL}${RESET}"
echo -e "Domain: ${DOMAIN}"
echo "$(date '+%Y-%m-%d %H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. llms.txt (15 points)
echo -ne "Checking /llms.txt... "
LLMS_STATUS=$(fetch_status "${URL}/llms.txt")
if [[ "$LLMS_STATUS" == "200" ]]; then
  LLMS_CONTENT=$(fetch_url "${URL}/llms.txt")
  if [[ ${#LLMS_CONTENT} -gt 100 ]]; then
    check "/llms.txt exists and has content" "pass" 15
    echo -e "${GREEN}✓${RESET}"
  else
    check "/llms.txt exists (but nearly empty)" "fail" 15 "Add products, description, and contact info to llms.txt"
    echo -e "${YELLOW}⚠ empty${RESET}"
  fi
else
  check "/llms.txt exists" "fail" 15 "Create /llms.txt following the llmstxt.org spec — AI crawlers use this for context"
  echo -e "${RED}✗ (HTTP ${LLMS_STATUS})${RESET}"
fi

# 2. robots.txt (10 points)
echo -ne "Checking /robots.txt... "
ROBOTS_STATUS=$(fetch_status "${URL}/robots.txt")
if [[ "$ROBOTS_STATUS" == "200" ]]; then
  ROBOTS_CONTENT=$(fetch_url "${URL}/robots.txt")
  BLOCKS_AI=false
  for BOT in GPTBot ClaudeBot PerplexityBot Google-Extended; do
    if echo "$ROBOTS_CONTENT" | grep -q "User-agent: ${BOT}" && echo "$ROBOTS_CONTENT" | grep -A2 "User-agent: ${BOT}" | grep -q "Disallow: /"; then
      BLOCKS_AI=true
      break
    fi
  done

  if $BLOCKS_AI; then
    check "/robots.txt (BLOCKS AI crawlers)" "fail" 10 "Remove Disallow rules for GPTBot, ClaudeBot, PerplexityBot, Google-Extended"
    echo -e "${RED}✗ blocks AI${RESET}"
  else
    check "/robots.txt (AI crawlers allowed)" "pass" 10
    echo -e "${GREEN}✓${RESET}"
  fi
else
  check "/robots.txt exists" "fail" 10 "Create /robots.txt — without it, some bots may not crawl your site"
  echo -e "${RED}✗ (HTTP ${ROBOTS_STATUS})${RESET}"
fi

# 3. sitemap.xml (10 points)
echo -ne "Checking /sitemap.xml... "
SITEMAP_STATUS=$(fetch_status "${URL}/sitemap.xml")
if [[ "$SITEMAP_STATUS" == "200" ]]; then
  check "/sitemap.xml exists" "pass" 10
  echo -e "${GREEN}✓${RESET}"
else
  check "/sitemap.xml exists" "fail" 10 "Create a sitemap.xml and submit to Google Search Console and Bing Webmaster Tools"
  echo -e "${RED}✗ (HTTP ${SITEMAP_STATUS})${RESET}"
fi

# Fetch homepage for HTML checks
echo -ne "Fetching homepage HTML... "
HTML=$(fetch_url "${URL}")
if [[ -z "$HTML" ]]; then
  echo -e "${RED}Failed to fetch homepage. Cannot run HTML checks.${RESET}"
  exit 1
fi
echo -e "${GREEN}✓${RESET}"

# 4. Schema.org JSON-LD (20 points)
echo -ne "Checking Schema.org JSON-LD... "
if echo "$HTML" | grep -q 'application/ld+json'; then
  SCHEMA_TYPES=""
  if echo "$HTML" | grep -qE '"@type":\s*"Organization"'; then
    SCHEMA_TYPES="${SCHEMA_TYPES} Organization"
  fi
  if echo "$HTML" | grep -qE '"@type":\s*"FAQPage"'; then
    SCHEMA_TYPES="${SCHEMA_TYPES} FAQPage"
  fi
  if echo "$HTML" | grep -qE '"@type":\s*"(Article|BlogPosting)"'; then
    SCHEMA_TYPES="${SCHEMA_TYPES} Article"
  fi
  if echo "$HTML" | grep -qE '"@type":\s*"(SoftwareApplication|Product)"'; then
    SCHEMA_TYPES="${SCHEMA_TYPES} SoftwareApplication"
  fi
  check "Schema.org JSON-LD present (${SCHEMA_TYPES})" "pass" 20
  echo -e "${GREEN}✓ (${SCHEMA_TYPES})${RESET}"
else
  check "Schema.org JSON-LD" "fail" 20 "Add JSON-LD structured data — at minimum Organization and FAQPage types"
  echo -e "${RED}✗${RESET}"
fi

# 5. OpenGraph tags (10 points)
echo -ne "Checking OpenGraph tags... "
OG_SCORE=0
for TAG in og:title og:description og:image og:url; do
  if echo "$HTML" | grep -q "property=\"${TAG}\""; then
    OG_SCORE=$((OG_SCORE + 1))
  fi
done
if [[ $OG_SCORE -ge 3 ]]; then
  check "OpenGraph tags (${OG_SCORE}/4 present)" "pass" 10
  echo -e "${GREEN}✓ (${OG_SCORE}/4)${RESET}"
else
  check "OpenGraph tags (${OG_SCORE}/4 present)" "fail" 10 "Add og:title, og:description, og:image, og:url meta tags"
  echo -e "${YELLOW}⚠ (${OG_SCORE}/4)${RESET}"
fi

# 6. Canonical URL (10 points)
echo -ne "Checking canonical URL... "
if echo "$HTML" | grep -q 'rel="canonical"'; then
  check "Canonical URL present" "pass" 10
  echo -e "${GREEN}✓${RESET}"
else
  check "Canonical URL" "fail" 10 "Add <link rel=\"canonical\" href=\"...\"> to prevent duplicate content issues"
  echo -e "${RED}✗${RESET}"
fi

# 7. hreflang (5 points)
echo -ne "Checking hreflang... "
if echo "$HTML" | grep -q 'hreflang'; then
  check "hreflang tags present" "pass" 5
  echo -e "${GREEN}✓${RESET}"
else
  check "hreflang tags" "fail" 5 "Add hreflang tags if you serve multiple languages (e.g. en, zh-TW)"
  echo -e "${YELLOW}⚠ not found${RESET}"
fi

# 8. Twitter Card (5 points)
echo -ne "Checking Twitter Card... "
if echo "$HTML" | grep -q 'twitter:card'; then
  check "Twitter Card meta tags" "pass" 5
  echo -e "${GREEN}✓${RESET}"
else
  check "Twitter Card" "fail" 5 "Add twitter:card, twitter:title, twitter:description, twitter:image"
  echo -e "${YELLOW}⚠${RESET}"
fi

# 9. Meta description length (5 points)
echo -ne "Checking meta description... "
META_DESC=$(echo "$HTML" | grep -oE 'name="description" content="[^"]*"' | head -1 | sed 's/name="description" content="//;s/"$//')
DESC_LEN=${#META_DESC}
if [[ $DESC_LEN -ge 120 && $DESC_LEN -le 165 ]]; then
  check "Meta description length (${DESC_LEN} chars)" "pass" 5
  echo -e "${GREEN}✓ (${DESC_LEN} chars)${RESET}"
elif [[ $DESC_LEN -gt 0 ]]; then
  check "Meta description length (${DESC_LEN} chars — ideal: 120-165)" "fail" 5 "Adjust meta description to 120-165 characters for best AI snippet extraction"
  echo -e "${YELLOW}⚠ (${DESC_LEN} chars)${RESET}"
else
  check "Meta description" "fail" 5 "Add a meta description tag — this is often used as the AI citation snippet"
  echo -e "${RED}✗ missing${RESET}"
fi

# 10. llms-full.txt (10 points, bonus)
echo -ne "Checking /llms-full.txt... "
LLMS_FULL_STATUS=$(fetch_status "${URL}/llms-full.txt")
if [[ "$LLMS_FULL_STATUS" == "200" ]]; then
  check "/llms-full.txt exists" "pass" 10
  echo -e "${GREEN}✓ (bonus)${RESET}"
else
  check "/llms-full.txt exists" "fail" 10 "Create /llms-full.txt with detailed product info, FAQ, team details"
  echo -e "${YELLOW}⚠ optional${RESET}"
fi

# Results
MAX=100
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BOLD}Results${RESET}"
echo ""

echo -e "${GREEN}Passed:${RESET}"
for p in "${PASSES[@]}"; do echo -e "$p"; done

if [[ ${#FAILS[@]} -gt 0 ]]; then
  echo ""
  echo -e "${RED}Failed:${RESET}"
  for i in "${!FAILS[@]}"; do
    echo -e "${FAILS[$i]}"
    if [[ $i -lt ${#WARNINGS[@]} ]]; then
      echo -e "${WARNINGS[$i]}"
    fi
  done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $SCORE -ge 80 ]]; then
  GRADE="A"
  COLOR=$GREEN
elif [[ $SCORE -ge 60 ]]; then
  GRADE="B"
  COLOR=$YELLOW
elif [[ $SCORE -ge 40 ]]; then
  GRADE="C"
  COLOR=$YELLOW
else
  GRADE="D"
  COLOR=$RED
fi

echo -e "${BOLD}AEO Score: ${COLOR}${SCORE}/${MAX} (Grade ${GRADE})${RESET}"
echo -e "Checks passed: ${PASS} / $((PASS + FAIL))"

if [[ $SCORE -ge 80 ]]; then
  echo -e "${GREEN}Your site is well-optimized for AI search engines.${RESET}"
elif [[ $SCORE -ge 60 ]]; then
  echo -e "${YELLOW}Good foundation. Focus on the failed checks above.${RESET}"
else
  echo -e "${RED}Significant AEO gaps. Address the failed checks above.${RESET}"
fi

echo ""
echo "Learn more: https://github.com/your-org/aeo-toolkit"
