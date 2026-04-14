# Schema.org Implementation Guide for AEO

> Schema.org structured data is one of the highest-leverage technical investments for AI engine optimization. This guide covers the 12 most important schema types, implementation patterns, and validation tools.

## Why Schema.org Matters for AI Engines

Schema.org markup transforms your HTML content into machine-readable data that AI engines can process directly — without parsing ambiguous natural language. When an AI engine crawls your page, it processes your JSON-LD blocks first, extracting entities, relationships, and facts before even reading the body text.

A well-structured Organization schema tells the AI exactly who you are, what you do, and how to contact you. A FAQPage schema pre-formats your Q&A content exactly the way AI wants to consume it. Without structured data, the AI has to guess — and guessing introduces errors.

Google AI Overview explicitly uses Schema.org data for Featured Snippets and AI Overview boxes. Perplexity and ChatGPT parse structured data when crawling pages for retrieval.

---

## JSON-LD vs. Microdata: Which to Use

There are three ways to add Schema.org markup: JSON-LD, Microdata, and RDFa. For AEO purposes, **always use JSON-LD**.

**JSON-LD** (JavaScript Object Notation for Linked Data):
- Lives in a `<script type="application/ld+json">` tag
- Completely separate from your HTML markup
- Easy to add, update, and debug without touching page layout
- Supported by all AI crawlers
- Google's officially recommended format

**Microdata**: Embedded in HTML attributes. Tightly coupled to your HTML structure, making it fragile and hard to maintain. Avoid for new implementations.

**RDFa**: XML-based, verbose, and rarely used. Avoid.

---

## The 12 Most Important Schema Types for AEO

### 1. Organization
**When to use**: Every website. Put this on your homepage.

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Your Company",
  "url": "https://your-domain.com",
  "description": "What you do in 2-3 sentences",
  "logo": {"@type": "ImageObject", "url": "https://your-domain.com/logo.png"},
  "sameAs": ["https://x.com/handle", "https://linkedin.com/company/name"]
}
```

**AEO impact**: High. Directly answers "what is [company]?" queries.

---

### 2. FAQPage
**When to use**: Any page with questions and answers. Extremely high AEO value.

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [{
    "@type": "Question",
    "name": "What is [Product]?",
    "acceptedAnswer": {
      "@type": "Answer",
      "text": "Direct answer in 2-4 sentences."
    }
  }]
}
```

**AEO impact**: Very high. FAQPage schemas are directly extracted by AI engines for Q&A retrieval. Write the `acceptedAnswer.text` as if it will be read aloud by an AI assistant — it often will be.

---

### 3. Article / BlogPosting
**When to use**: Every blog post or news article.

Key fields:
- `headline`: The article title (under 110 characters)
- `datePublished` and `dateModified`: ISO 8601 format (YYYY-MM-DD)
- `author`: Person schema with name and URL
- `publisher`: Organization schema
- `description`: 2-3 sentence summary

**AEO impact**: High. `dateModified` affects freshness scoring. `author` contributes to E-E-A-T signals.

---

### 4. SoftwareApplication
**When to use**: Any SaaS product or web application.

Key fields: `name`, `applicationCategory`, `operatingSystem`, `offers` (with pricing), `aggregateRating`

**AEO impact**: High. Directly serves "what does [app] do?" and "how much does [app] cost?" queries.

---

### 5. Product
**When to use**: Physical or digital products with explicit pricing.

Similar to SoftwareApplication but includes `sku`, `brand`, `offers` with `availability` and `price`.

**AEO impact**: High for e-commerce and product-focused queries.

---

### 6. BreadcrumbList
**When to use**: Every page except the homepage.

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    {"@type": "ListItem", "position": 1, "name": "Home", "item": "https://your-domain.com"},
    {"@type": "ListItem", "position": 2, "name": "Blog", "item": "https://your-domain.com/blog"},
    {"@type": "ListItem", "position": 3, "name": "Article Title", "item": "https://your-domain.com/blog/article"}
  ]
}
```

**AEO impact**: Medium. Helps AI engines understand your site structure and the relationship between pages.

---

### 7. WebSite (with SearchAction)
**When to use**: Your homepage. Enables sitelinks search in Google.

```json
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Your Company",
  "url": "https://your-domain.com",
  "potentialAction": {
    "@type": "SearchAction",
    "target": "https://your-domain.com/search?q={search_term_string}",
    "query-input": "required name=search_term_string"
  }
}
```

**AEO impact**: Medium. Primarily affects Google. Signals site structure to crawlers.

---

### 8. HowTo
**When to use**: Step-by-step tutorial content.

```json
{
  "@context": "https://schema.org",
  "@type": "HowTo",
  "name": "How to Set Up X",
  "step": [
    {"@type": "HowToStep", "position": 1, "name": "Step Name", "text": "Step instructions."},
    {"@type": "HowToStep", "position": 2, "name": "Step Name", "text": "Step instructions."}
  ]
}
```

**AEO impact**: Very high for instructional queries. AI engines extract HowTo steps directly and present them as numbered instructions.

---

### 9. Person
**When to use**: Author pages, team pages, founder profiles.

Key fields: `name`, `jobTitle`, `worksFor`, `url`, `sameAs` (social profiles), `knowsAbout`

**AEO impact**: Medium-High. Builds author authority for E-E-A-T. Helps AI identify the human expert behind content.

---

### 10. Review / AggregateRating
**When to use**: Product pages where you display customer reviews.

Only use this if you actually have and display reviews on the page. Google penalizes self-serving review markup.

**AEO impact**: Medium. Adds credibility signals to product citations.

---

### 11. Event
**When to use**: Webinars, conferences, product launches.

Key fields: `name`, `startDate`, `endDate`, `location` (VirtualLocation for online), `organizer`, `offers`

**AEO impact**: Medium for event-related queries. Especially useful for "upcoming events" retrieval.

---

### 12. VideoObject
**When to use**: Pages with embedded videos as primary content.

Key fields: `name`, `description`, `thumbnailUrl`, `uploadDate`, `duration` (ISO 8601), `contentUrl`

**AEO impact**: Medium. Helps AI engines understand video content and cite it for "how to" queries.

---

## Common Schema.org Mistakes

### Mistake 1: Marking up content that isn't visible on the page
Schema.org should describe visible content. If your FAQ schema contains questions that don't appear in the page HTML, Google will flag it as spammy markup. AI engines may also distrust the structured data if it contradicts the visible content.

### Mistake 2: Wrong `@type` for the content
Using `Article` for a product page, or `Organization` on individual blog posts, confuses both search engines and AI engines. Match the schema type to what the page actually is.

### Mistake 3: Missing required properties
Each schema type has recommended properties. Missing `datePublished` on an Article, or `name` on an Organization, reduces the schema's value significantly.

### Mistake 4: Stale schema data
Updating your pricing page but forgetting to update the `Offer` price in your SoftwareApplication schema creates a contradiction. AI engines may cite the stale schema data. Treat schema updates as part of your content update workflow.

### Mistake 5: Nesting schemas incorrectly
Schema.org supports nesting (an Article has an `author` which is a `Person`). Incorrect nesting — like putting an Organization schema where a Person schema is expected — produces invalid structured data that validators will flag.

---

## Validation Tools

Before deploying schema markup, validate it:

1. **Google Rich Results Test**: https://search.google.com/test/rich-results
   Tests specific schema types that Google uses for rich results.

2. **Schema.org Validator**: https://validator.schema.org
   Validates any schema markup against the full Schema.org spec.

3. **Structured Data Linter**: http://linter.structured-data.org
   Alternative validator with verbose error output.

4. **Browser DevTools**: Search for `application/ld+json` in the Sources panel, copy the content, and validate it as JSON first (it must be valid JSON before it can be valid Schema.org).

---

## Implementation Checklist

- [ ] Organization schema on homepage
- [ ] FAQPage schema on homepage and key landing pages
- [ ] Article/BlogPosting on every blog post (with datePublished, dateModified, author)
- [ ] SoftwareApplication or Product schema on product pages (with pricing)
- [ ] BreadcrumbList on all pages except homepage
- [ ] WebSite schema on homepage
- [ ] HowTo schema on tutorial content
- [ ] Person schema on author profile pages
- [ ] All schemas validated with Google Rich Results Test
- [ ] `dateModified` updated whenever content changes
