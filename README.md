# AEO Toolkit — Answer Engine Optimization 完整工具包

> 讓你的網站被 ChatGPT、Perplexity、Claude、Google AI Overview 引用的完整實作工具包。

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Built with](https://img.shields.io/badge/built%20with-Claude%20Code-5436da.svg)](https://www.anthropic.com/claude-code)

## 什麼是 AEO？

AEO（Answer Engine Optimization）= 讓 AI 搜尋引擎在回答用戶問題時，引用你的網站當作答案來源。

傳統 SEO 讓你出現在搜尋結果頁；AEO 讓你出現在 AI 的回答裡。

## 為什麼需要 AEO？

- **2026 年 40%+ 搜尋走 AI**：ChatGPT、Perplexity、Claude、Gemini 等
- **AI 搜尋引擎不點你的網站，它們直接複製你的內容**
- **被引用 = 流量來源 = 信任度**
- **沒做 AEO = 在 AI 時代隱形**

## 這個 Toolkit 包含什麼？

```
aeo-toolkit/
├── templates/          # 可直接複製使用的範本
│   ├── llms.txt                    # AI 爬蟲導覽（llmstxt.org 規格）
│   ├── llms-full.txt               # AI 完整參考
│   ├── robots.txt                  # 允許 GPTBot/ClaudeBot 等
│   ├── robots-agent-ready.txt      # Level 2 版：加 Content-Signal（NEW）
│   ├── vercel-agent-ready.json     # Vercel host 配置含 Link headers（NEW）
│   ├── schema-organization.json    # Organization JSON-LD
│   ├── schema-faqpage.json         # FAQPage JSON-LD
│   ├── schema-article.json         # Article JSON-LD
│   ├── schema-breadcrumb.json      # BreadcrumbList JSON-LD
│   ├── opengraph-meta.html         # OpenGraph/Twitter Card
│   └── .well-known/                # Agent-Ready 協議檔（NEW）
│       ├── mcp/server-card.json    # MCP Server Card (SEP-1649)
│       ├── agent-card.json         # A2A Agent Card
│       ├── agent-skills/           # Claude Agent Skills
│       ├── api-catalog             # RFC 9727 linkset+json
│       ├── ai-plugin.json          # ChatGPT plugin manifest
│       ├── oauth-protected-resource  # RFC 9728
│       └── oauth-authorization-server # RFC 8414
│
├── examples/           # 完整實作範例
│   ├── simple-site/                # 簡單靜態網站範例
│   ├── blog-post/                  # AEO 優化部落格文章範本
│   └── landing-page/               # Landing page 範本
│
├── scripts/            # 自動化工具
│   ├── verify-aeo.sh               # 驗證你的網站 AEO 設定
│   ├── agent-ready-scan.sh         # 掃描 Agent-Ready 等級（NEW）
│   ├── generate-llms-txt.py        # 從網站結構自動產生 llms.txt
│   └── count-api.js                # Vercel Edge Function 計數 API
│
└── docs/               # 深度知識文檔
    ├── how-ai-engines-cite.md      # AI 搜尋引擎的引用邏輯
    ├── citation-triggers.md        # 什麼觸發引用
    ├── content-strategy.md         # AEO 內容策略
    ├── schema-org-guide.md         # Schema.org 實作指南
    ├── common-mistakes.md          # 常見錯誤
    └── platform-differences.md     # 各平台差異（ChatGPT vs Perplexity vs Claude）
```



## 🤖 Agent-Ready 升級（AEO v2）

AEO 讓 AI **引用**你的內容；Agent-Ready 讓 AI **呼叫**你的服務。

### 5 等級評分（[isitagentready.com](https://isitagentready.com)）

| Level | 名稱 | 關鍵檔案 |
|---|---|---|
| 1 | Basic Web Presence | robots.txt + sitemap |
| 2 | Bot-Aware | + Content-Signal |
| 3 | Agent-Accessible | + Link headers + Markdown 協商 |
| 4 | Agent-Integrated | + MCP/A2A/Agent Skills/API Catalog |
| 5 | Agent-Native | + OAuth 發現元資料 |

### 一鍵升級

```bash
# 1. 複製所有 agent-ready 模板
cp -r templates/.well-known /your-site/public/
cp templates/robots-agent-ready.txt /your-site/public/robots.txt
cp templates/vercel-agent-ready.json /your-site/vercel.json

# 2. 批次替換佔位符
find /your-site/public/.well-known -type f -exec sed -i '' \
  -e 's|{{SITE_URL}}|https://example.com|g' \
  -e 's|{{COMPANY_NAME}}|你的公司|g' \
  -e 's|{{COMPANY_SLUG}}|your-company|g' \
  -e 's|{{CONTACT_EMAIL}}|you@domain.com|g' {} \;

# 3. 驗證等級
bash scripts/agent-ready-scan.sh https://example.com
```

詳細說明：[docs/agent-ready-guide.md](docs/agent-ready-guide.md)

## 快速開始（5 分鐘）

### 1. 複製範本到你的網站根目錄
```bash
cp templates/llms.txt templates/robots.txt /your-site/public/
```

### 2. 編輯 `llms.txt` 改成你的網站資訊
```markdown
# 你的公司名稱

> 你的一句話介紹（30-60 字）

## Products
- [產品 A](https://your-domain.com/product-a): 描述
- [產品 B](https://your-domain.com/product-b): 描述

## Contact
- Email: you@domain.com
```

### 3. 在你的 `<head>` 加入 Schema.org JSON-LD
```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "你的公司",
  "url": "https://your-domain.com"
}
</script>
```

### 4. 驗證設定
```bash
bash scripts/verify-aeo.sh https://your-domain.com
```

## 核心概念：CITABLE 框架

AI 搜尋引擎引用一個網頁需要滿足這 7 個條件：

| 字母 | 意義 | 實作方式 |
|------|------|---------|
| **C** | Clear Entity 清晰實體 | 開頭 2-3 句明確命名主體 |
| **I** | Intent Architecture 意圖架構 | 涵蓋主問題 + 3-5 個衍生問題 |
| **T** | Third-party Validation 第三方驗證 | Reddit、GitHub、評論 |
| **A** | Answer-grounded 答案基礎 | 每個主張附可驗證來源 |
| **B** | RAG-chunked 分塊結構 | 200-400 字段落 + 清晰 H2/H3 |
| **L** | Latest & Consistent 最新一致 | 可見時間戳 + 跨平台資訊一致 |
| **E** | Entity Graph 實體圖譜 | Schema 標記 + 明確關係陳述 |

## 各 AI 搜尋引擎的引用邏輯

| 平台 | 怎麼找來源 | 偏好什麼內容 |
|------|-----------|-------------|
| **ChatGPT** | Bing 索引 + 即時爬蟲 | 百科全書式、清晰實體定義 |
| **Perplexity** | 即時爬全網 | Reddit 討論、最新內容、原創研究 |
| **Claude** | 訓練資料 + 搜尋 | 正式權威語氣、結構化內容 |
| **Google AI Overview** | Google 索引 | Schema.org、FAQ、權威性 |

詳細分析請看 [docs/platform-differences.md](docs/platform-differences.md)

## 實戰案例：海衫科技

本 Toolkit 的所有技術都在 [harrysontech.xyz](https://harrysontech.xyz) 驗證過。

- **2 位工程師** + **AI Agent 工作流**
- **8 個產品線**同時維運
- **13 篇技術文章**全部 AEO 優化
- **完整 Schema.org 實作**
- **即時流量儀表板**

## 貢獻

歡迎 PR！特別需要：
- 更多語言的 Schema.org 範本
- 更多 AI 搜尋引擎的引用數據
- 實戰案例分享

## License

MIT — 完全開源，任意使用。

## 作者

[HarrysonTech 海衫科技](https://harrysontech.xyz) · [harrison.tech.0857@gmail.com](mailto:harrison.tech.0857@gmail.com)

---

**「SEO 讓你在 Google 排名第一，AEO 讓你成為 AI 的答案。」**
