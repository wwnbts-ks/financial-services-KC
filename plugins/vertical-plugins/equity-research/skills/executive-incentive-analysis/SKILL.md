---
name: executive-incentive-analysis
description: Analyze key management incentives for a public company — total pay (cash + equity/ESOP), ESOP/equity-incentive structure benchmarked against main competitors, the performance targets and incentives those create, a multi-horizon (3/5/10-year) bridge of each executive's equity stake (shares granted, shares bought with cash, shares sold and proceeds, net change), and related-party transactions as a misalignment risk. Use when the user asks to "analyze exec comp / executive incentives", "summarize management compensation", "look at the ESOP / equity incentive plan", "compare incentives vs peers", "what are management incentivized to do", "how much did insiders / management sell", "how much have insiders bought", "insider selling", "management stake change", "related-party transactions / 关联交易", or "compensation alignment" for a named company. Covers US (DEF 14A / Form 4), HK-listed (annual report remuneration + connected transactions + HKEXnews disclosures), and China A-share (年报高管薪酬 / 股权激励 / 减持 / 增持 / 关联交易) disclosure regimes.
---

# Executive Incentive Analysis

Produce a concise, source-disciplined read on how a public company's **key management** is paid, what their equity incentives actually reward, and how their personal equity stake has changed over time. The goal is not to list numbers — it is to answer **"what is this management team incentivized to do, and are they buying into the story or cashing out?"**

## When to Use

Use when the user asks any of:
- "Summarize [Company]'s executive / management compensation"
- "Analyze the ESOP / equity incentive plan for [Company]"
- "What are the vesting / performance targets, and what do they incentivize?"
- "How much have insiders / management sold over the last 3 years?"
- "Is management's comp aligned with shareholders?"

**Do NOT use for:**
- Full equity research initiation or earnings note → use those skills; this is a focused module that can feed into them.
- Private companies with no public comp disclosure → state that data is unavailable rather than estimating.

## Source Discipline ⭐ MANDATORY

Always work from primary disclosure. Never infer comp figures from secondary aggregators (Salary.com, news summaries) without tracing to filing. State the filing, the period it covers, and the URL for every figure.

**By market:**

| Market | Comp & ESOP source | Insider selling source |
| --- | --- | --- |
| **US** | Proxy statement (DEF 14A) — Summary Compensation Table, Grants of Plan-Based Awards, Outstanding Equity at FY-End, CD&A for targets | Form 4 / Form 144 (SEC EDGAR) for all buys, sells, grants, option exercises; 10b5-1 plan disclosures |
| **HK-listed** | Annual report — Directors' & senior management emoluments note; share option / award scheme circulars (HKEXnews) | HKEXnews "Disclosure of Interests" (Forms 3A/3B), shareholding change filings, share pledge disclosures |
| **China A-share** | 年报「董事、监事和高级管理人员」薪酬章节; 股权激励计划草案/考核办法 (巨潮 cninfo) | 减持/增持公告、权益变动报告书、大宗交易明细、股份质押公告 (交易所 + cninfo) |

If the company is dual-listed or VIE-structured, reconcile across regimes and flag where disclosures differ (US ADR proxies vs. HK annual report often differ in scope).

**A-share data tooling.** The cninfo filings above are the source of record; two tools speed up retrieval. Use the **akshare-one MCP** for management share transactions and holdings (高管增减持, 持股变动) — it pulls the disclosure-derived data directly, and it is the primary tool for filling the stake-bridge in step 4. Use the **tushare Python SDK** (token at `~/.config/tushare/token`; call `pro.income` / `pro.balancesheet` / `pro.fina_indicator` / `pro.daily_basic`) for the financial and market-cap base — shares outstanding, market value, and the financial backdrop a comp figure is sized against. Note the boundary: tushare's announcement endpoint (`anns_d`) is gated behind higher credit tiers and may be unavailable, so 股权激励考核办法 and 减持公告 detail still come from cninfo filings or akshare, not tushare. Either tool is a faster path to the same primary data — never a substitute for citing the underlying filing.

## When a Primary Source Can't Be Reached

Primary filings sometimes can't be fetched — a PDF host is unreachable, a fetch times out, TLS/certificate errors, rate limits, or paywalled connector data. **Do not stop the analysis, and do not silently fill the gap with secondary data dressed up as primary.** Degrade gracefully instead:

1. **Name the gap precisely** — which document, which issuer, and why it failed (e.g., "could not retrieve 三花智控 2024 限制性股票激励计划 from cninfo — fetch failed"). Do not just omit the line.
2. **Use what you do have, labeled by tier.** Mark every figure as **[primary]** (traced to a filing) or **[secondary, unverified]** (from search snippets, news, aggregators pending confirmation). A secondary number is acceptable as a placeholder *only* if it carries this label and a note to confirm against the filing.
3. **Produce the partial analysis anyway** — the sections you can support stand; the blocked sections show what's missing rather than a fabricated number or a dead stop.
4. **End with a "Primary sources to confirm" checklist** — the exact filings still needed, with the issuer/section/expected location, so a human can pull them manually.

The rule is unchanged — conclusions rest on primary disclosure — but a fetch failure produces a *labeled, honest partial* with a follow-up list, never a confident number that was never verified and never a 1-minute stall that ends in an error.

## Workflow

### 1. Define "key management"
Scope is **executive management only**. Include executive directors and senior management (US: NEOs; HK: executive directors + senior management; A-share: 执行董事 + 高级管理人员). **Exclude non-executive directors, independent directors, and (for A-share) 监事 / supervisors** — they are not running the business and their incentives are a separate question. State explicitly who is in scope, and do not silently broaden or narrow the set.

### 2. Compensation summary (Requirement 1)
For each key executive and the most recent disclosed fiscal year (plus 1-2 prior years for trend):
- **Cash**: base salary + cash bonus / non-equity incentive.
- **Equity/ESOP**: grant-date fair value of options + RSUs/PSUs/restricted shares; note this is *granted* value, not realized.
- **Other**: pension, perquisites, other.
- **Total**, and the **cash vs. equity mix** (a high-equity mix signals longer-horizon alignment; a high-cash mix the opposite).

Present as one clean table. Distinguish clearly between **granted** (fair value at grant) and **realized/realizable** (what they actually got) — conflating these is the most common error.

### 3. ESOP / equity-incentive structure & targets (Requirement 2)
This is the analytical core. Cover:
- **Instrument**: options vs. RSUs vs. PSUs vs. restricted shares; strike price relative to grant-date price.
- **Vesting**: time-based schedule, cliff, total vesting period (longer = better alignment).
- **Performance conditions**: the actual metrics and thresholds. Quote the metric and target precisely (e.g., revenue CAGR ≥ X%, ROE ≥ Y%, relative TSR vs. an index). For A-share 股权激励, summarize the 业绩考核 grid (公司层面 + 个人层面) and the 解锁/归属比例 at each tier.
- **Peer comparison** — benchmark against the company's main competitors. Pull the equivalent equity-incentive structure for 2-3 closest peers (same sector, comparable size) and compare on: pay mix (cash vs. equity), the *type* of performance metric used, and how demanding the thresholds are. The question is whether this company's targets are stretch goals or soft relative to what peers must hit — a target that looks fine in isolation can be revealed as easy once you see peers being held to tougher bars. Note where peers tie pay to returns/margin/relative TSR while this company rewards only growth, or vice versa. State the peer set explicitly and cite each peer's disclosure.
- **Incentive read** — the payoff: given those metrics, what behavior is rewarded? Flag misalignment risks: targets that reward revenue growth regardless of margin/ROIC; absolute (not relative) TSR in a rising market; soft/easily-hit thresholds (especially relative to peers); repricing history; large unconditional time-vested grants.

### 4. Equity stake bridge — 3 / 5 / 10 years (Requirement 3)
For each key executive (and in aggregate), reconstruct how their personal stake changed over the trailing **3, 5, and 10 years**. The point of three horizons is to separate recent behavior from lifetime pattern — a founder may have been a net buyer for a decade but a heavy seller in the last 3 years, and that contrast is the signal.

For each horizon, tally:
- **Granted** — shares received via equity awards (options exercised into shares, RSU/PSU vesting, restricted-share grants). Note this is paid for by the company, not the executive.
- **Bought** — shares purchased with the executive's own cash on the open market, and the total cash outlay. Open-market buys are the strongest alignment signal; weight them heavily.
- **Sold** — shares disposed of and gross proceeds. Split discretionary sales from pre-arranged-plan sales (US 10b5-1); discretionary clustered selling is more informative.
- **Net change** in shares held, and ending stake vs. starting stake (absolute shares and % of shares outstanding).

Beyond the counts, capture:
- Sales/buys as a % of that executive's holdings at the time.
- **Pledged shares** — common and material for A-share / HK founders; pledging is economically close to monetizing without a reportable sale, so flag it.
- Context: lockup expiries, secondary placements, timing relative to results or price highs.

Where horizons exceed clean disclosure (e.g., A-share 大宗交易 with lagged price, or pre-IPO grants outside the filing window), state the gap rather than fabricating — give the bounded figure and note what's missing.

A useful framing: **company-funded inflow (granted) vs. own-cash inflow (bought) vs. outflow (sold)**. Management whose stake grows only through grants while they steadily sell is being paid in equity and converting it to cash — a different alignment picture from management buying with their own money.

### 5. Related-party transactions
Study related-party transactions (RPTs) separately, because the most damaging misalignment often sits outside the comp table entirely — value extracted through dealings between the company and entities the executives/controllers own or control. Identify, from primary disclosure:
- **The counterparties** — entities connected to key management or the controlling shareholder (US: related-person transactions in the proxy; HK: connected transactions per Listing Rules Ch.14A on HKEXnews; A-share: 关联交易 section of the 年报 + 关联交易公告 on cninfo).
- **Type and scale** — sales/purchases of goods or services, loans and guarantees, asset transfers, leasing, fund occupation (资金占用). Quantify each in currency terms and as a % of revenue / total assets / net profit.
- **Pricing fairness** — whether terms are at arm's length or off-market; one-sided pricing is the tell.

**If RPTs are large** — material in scale, recurring, or off-market in pricing — **list them explicitly as a misalignment risk** alongside the equity-incentive flags from step 3. Large RPTs mean management can be enriched regardless of how the equity incentives are designed, which can dominate the overall alignment read. State scale, counterparty, and why it's a concern; flag fund occupation and guarantees for connected parties as especially serious.

### 6. Synthesis
Two or three sentences: is comp structured for long-term value creation or near-term extraction; do the equity targets reward the right things (and how do they compare to peers); is management adding to or reducing its stake; and do related-party dealings undercut the alignment the comp structure implies. This is a judgment, stated plainly, with the evidence behind it.

## Output Format

1. **Compensation summary table** (key execs × cash / equity / total, latest FY + trend).
2. **ESOP structure & targets** — short prose, with a targets/thresholds sub-table if multi-tier, plus a peer-comparison sub-table (this company vs. 2-3 main competitors).
3. **Incentive read** — what the structure rewards and the misalignment flags.
4. **Equity stake bridge table** (key exec × horizon × granted / bought (+cash) / sold (+proceeds) / net change / ending % o/s), for 3, 5, and 10 years.
5. **Related-party transactions** — table of material RPTs (counterparty × type × scale × % of revenue/assets), with large/off-market items flagged as misalignment risk.
6. **Synthesis** — alignment verdict.

Every figure carries a citation: filing name, period, and URL. Keep granted-vs-realized distinct throughout. Do not give investment advice or a buy/sell call — describe alignment, leave the conclusion to the reader.

---

*Version 0.3 — last updated 2026-06-05*
*0.3: added A-share data-tooling note (akshare-one MCP for insider transactions, tushare SDK for financial/market-cap base).*
*0.2: added graceful-degradation protocol for unreachable primary sources (tiered labeling + follow-up checklist).*
