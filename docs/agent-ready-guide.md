# Agent-Ready 5-Level 評分實作指南

> 對應 [isitagentready.com](https://isitagentready.com) 評分系統，5 個等級從 Level 1 到 Level 5 Agent-Native。

## 為什麼 AEO 要做 Agent-Ready？

傳統 AEO 聚焦「AI 引擎看得懂你的內容」（llms.txt、Schema.org）。**Agent-Ready 更進一步：讓 AI Agent 能自動發現並介接你的服務**。

關鍵差別：
- **AEO（被引用）**：Perplexity/ChatGPT 讀完你的網頁，把你的內容寫進回答
- **Agent-Ready（被呼叫）**：AI Agent 發現你的 MCP Server / A2A Agent，把你的服務串進它的工具鏈

Agent 時代，沒做 Agent-Ready = 沒被 AI 工具生態系收錄。

## 5 個等級

| Level | 名稱 | 核心能力 | 本 toolkit 對應檔案 |
|---|---|---|---|
| 1 | Basic Web Presence | robots.txt + sitemap | `templates/robots.txt`, 自行產生 sitemap.xml |
| 2 | Bot-Aware | AI bot 規則 + Content-Signal | `templates/robots-agent-ready.txt` |
| 3 | Agent-Accessible | Link headers + Markdown 協商 | `templates/vercel-agent-ready.json` |
| 4 | Agent-Integrated | MCP Card + A2A Card + Agent Skills + API Catalog | `templates/.well-known/*` |
| 5 | Agent-Native | OAuth metadata + 完整協議檔 | `templates/.well-known/oauth-*` |

## 實作步驟

### Step 1. Bot-Aware（Level 2）

複製 `templates/robots-agent-ready.txt` 到你的 `/robots.txt`：

```bash
cp templates/robots-agent-ready.txt public/robots.txt
sed -i '' 's|{{SITE_URL}}|https://example.com|g' public/robots.txt
```

關鍵：`Content-Signal: search=yes, ai-input=yes, ai-train=yes`（單數 **Content-Signal**，不是複數）。

### Step 2. Agent-Accessible（Level 3）

**首頁加 Link headers** — 把所有 agent 資源用 RFC 8288 Link 欄暴露：

使用 `templates/vercel-agent-ready.json`（Vercel/其他 host 類似配置）。

**Markdown 協商** — Accept: text/markdown 時回傳 `.md` 版本：

```bash
# 建 /index.md — 首頁內容的 markdown 版
echo "# 公司名\n\n..." > public/index.md
```

Vercel config（已在 `vercel-agent-ready.json`）用 `has: Accept=text/markdown` → `redirect /index.md`。

### Step 3. Agent-Integrated（Level 4）

複製整個 `.well-known/` 目錄到你的 `public/`：

```bash
cp -r templates/.well-known public/
# 替換佔位符
find public/.well-known -type f -exec sed -i '' \
  -e 's|{{SITE_URL}}|https://example.com|g' \
  -e 's|{{COMPANY_NAME}}|Your Company|g' \
  -e 's|{{COMPANY_SLUG}}|your-company|g' \
  -e 's|{{CONTACT_EMAIL}}|contact@example.com|g' \
  -e 's|{{COMPANY_DESCRIPTION}}|你的公司描述|g' \
  -e 's|{{COMPANY_DESCRIPTION_EN}}|Your company description|g' \
  {} \;
```

包含：
- `.well-known/mcp/server-card.json` — MCP Server Card (SEP-1649)
- `.well-known/agent-card.json` — A2A Agent Card
- `.well-known/agent-skills/index.json` + `agent-skills/<id>/SKILL.md` — Claude Agent Skills
- `.well-known/api-catalog` — RFC 9727 linkset+json
- `.well-known/ai-plugin.json` — ChatGPT plugin manifest

### Step 4. Agent-Native（Level 5）

`oauth-protected-resource` 和 `oauth-authorization-server` 已在 Step 3 複製。即使站點沒 OAuth 也要放（宣告資源為公開即可）。

## 驗證

```bash
# 官方評分 API
curl -s -X POST "https://isitagentready.com/api/scan" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://your-domain.com"}' | jq '.level, .levelName'
```

預期輸出：
```
5
"Agent-Native"
```

## 實戰案例

**HarrysonTech（harrysontech.xyz）**：
- 升級前：Level 1 "Basic Web Presence"
- 升級後：Level 5 "Agent-Native"（12/18 pass）
- 時間：約 30 分鐘 + 4 輪迭代
- commits：`chore/agent-ready-upgrade` on haishan-tech

## 規格參考

- [isitagentready.com](https://isitagentready.com) — 官方評分標準
- [SEP-1649 MCP Server Card](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/2127)
- [A2A Protocol](https://a2a-protocol.org)
- [Content Signals](https://contentsignals.org)
- [RFC 9727 API Catalog](https://www.rfc-editor.org/rfc/rfc9727)
- [RFC 9728 OAuth Protected Resource Metadata](https://www.rfc-editor.org/rfc/rfc9728)
- [RFC 8414 OAuth Authorization Server Metadata](https://www.rfc-editor.org/rfc/rfc8414)
- [RFC 8288 Web Linking](https://www.rfc-editor.org/rfc/rfc8288)

## Content-Signal 決策指南

| 策略 | search | ai-input | ai-train | 適合對象 |
|---|---|---|---|---|
| 全開放 | yes | yes | yes | AI 公司、想被 LLM 熟知的品牌 |
| 允許引用、禁訓練 | yes | yes | no | 新聞網站、付費內容 |
| 僅搜尋 | yes | no | no | 高價值 UGC、論壇 |
| 全拒絕 | no | no | no | 私有內容（但應改用密碼保護） |

預設建議：**全開放**。做 AEO 的目的就是被看見，限制會削弱被引用機會。
