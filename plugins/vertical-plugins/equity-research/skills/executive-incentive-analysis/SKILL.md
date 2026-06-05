---
name: executive-incentive-analysis
description: Analyze a public company's key-management incentives — pay (cash + equity), equity-incentive structure and performance targets vs. peers, a 3/5/10-year bridge of each executive's stake (granted / bought / sold / net), and related-party transactions as a misalignment risk. Use when the user asks to analyze exec comp / executive incentives / management compensation, the ESOP or 股权激励 plan, vesting or performance targets, insider buying or selling, 减持/增持, management stake change, 关联交易, peer comparison of incentives, or compensation alignment for a named company. Covers US, HK-listed, and China A-share disclosure.
---

# Executive Incentive Analysis

Source-disciplined read on how a company's executive management is paid, what their equity incentives reward, and whether they are buying in or cashing out. Answer: **what is management incentivized to do, and are they aligned with shareholders?** Not for full initiation/earnings notes (use those skills); for private companies with no disclosure, say so rather than estimate.

## Source Discipline ⭐ MANDATORY

Work only from primary disclosure. Cite filing, period, and URL for every figure. Never infer comp from secondary aggregators without tracing to filing.

| Market | Comp & ESOP source | Insider transaction source |
| --- | --- | --- |
| **US** | DEF 14A — Summary Comp Table, Grants of Plan-Based Awards, Outstanding Equity at FY-End, CD&A | Form 4 / 144 (EDGAR); 10b5-1 plans |
| **HK** | Annual report emoluments note; option/award scheme circulars (HKEXnews) | HKEXnews Disclosure of Interests (3A/3B), shareholding changes, pledges |
| **A-share** | 年报「董监高」薪酬章节; 股权激励计划草案/考核办法 (cninfo) | 减持/增持公告、权益变动报告书、大宗交易、股份质押公告 (交易所 + cninfo) |

For dual-listed/VIE names, reconcile across regimes and flag where disclosures differ.

**A-share tooling** (faster path to the same primary data, never a substitute for citing the filing): use **akshare-one MCP** for 高管增减持/持股变动 (primary tool for the step-4 bridge); use **tushare SDK** (token at `~/.config/tushare/token`; `pro.income`/`balancesheet`/`fina_indicator`/`daily_basic`) for shares outstanding, market cap, and financial base. tushare `anns_d` (announcements) is gated/often unavailable, so 考核办法 and 减持公告 text come from cninfo or akshare.

**Local cache:** save every retrieved filing to `./research-cache/<ticker>/` (e.g. `./research-cache/002050.SZ/`); also where the user drops manual downloads. Check this folder first and read from disk before re-fetching.

## When a Primary Source Can't Be Reached

A-share/HK filings often can't be fetched (blocked PDFs, timeouts, TLS/proxy errors; akshare/tushare don't cover 考核办法 or full 减持公告 text). For a **core** input (annual report, incentive plan, 减持/增持 disclosure), in order:

1. **Try alternate tools** — akshare for the same data point, tushare for series data. Exhaust automated paths first.
2. **Still missing → STOP and ask the user.** Do not fabricate or substitute a secondary number for a core input. State: **what's missing** (exact document, e.g. "三花智控 2024年报"), **where to get it** (cninfo 公告页 / HKEXnews / EDGAR + search term), **where to put it** (`./research-cache/<ticker>/`, full path). Ask them to reply when done.
3. **Resume** from the pause point when the user confirms — read from the cache folder, don't restart.
4. **Labeled partial, last resort only** (user declines / file doesn't exist): mark each figure **[primary]** or **[secondary, unverified]**, leave blocked sections marked missing not guessed, end with a "Primary sources to confirm" checklist.

The stall is deliberate and informative — never silent, never a fabricated fill.

## Workflow

**0. Output language.** Ask up front: 中文为主还是英文为主. Keep proper nouns, filing names, financial terms in original form either way (减持公告, DEF 14A, RSU). Don't re-ask within a run.

**1. Define key management.** Executive management only — executive directors + senior management (US: NEOs; A-share: 执行董事 + 高管). **Exclude** non-executive/independent directors and A-share 监事. State who is in scope.

**2. Compensation summary (Req 1).** Per executive, latest FY + 1-2 prior for trend, as one table: cash (base + bonus); equity (grant-date fair value of options/RSUs/PSUs); other (pension, perks); total; cash-vs-equity mix. Keep **granted** (fair value at grant) distinct from **realized** — conflating them is the most common error.

**3. Equity-incentive structure & targets (Req 2)** — the analytical core:
- **Instrument**: options/RSU/PSU/restricted; strike vs. grant-date price.
- **Vesting**: schedule, cliff, total period (longer = better alignment).
- **Performance conditions**: actual metrics and thresholds, quoted precisely (revenue CAGR ≥ X%, ROE ≥ Y%, relative TSR). For A-share, the 业绩考核 grid (公司+个人) and 解锁/归属比例 per tier.
- **Peer comparison**: pull the equivalent structure for 2-3 closest peers; compare pay mix, metric type, and threshold toughness. Are the targets stretch or soft relative to what peers must hit? Cite each peer's disclosure.
- **Incentive read**: what behavior do the metrics reward? Flag misalignment — growth rewarded regardless of margin/ROIC; absolute (not relative) TSR in a rising market; soft thresholds (esp. vs. peers); repricing history; large unconditional time-vested grants.

**4. Equity stake bridge — 3/5/10 years (Req 3).** Per executive and aggregate, for each horizon (three horizons separate recent behavior from lifetime pattern):
- **Granted** (company-funded), **Bought** (own cash on market + outlay — strongest alignment signal), **Sold** (shares + gross proceeds; split discretionary vs. 10b5-1), **Net change** + ending stake (shares and % o/s).
- Also: buys/sells as % of holdings at the time; **pledged shares** (material for A-share/HK founders — near-monetization without a reportable sale, flag it); lockups, secondary placements, timing vs. price highs.
- Frame as company-funded (granted) vs. own-cash (bought) vs. outflow (sold): a stake growing only via grants while steadily selling ≠ buying with own money.
- Where disclosure is incomplete (大宗交易 lagged price, pre-IPO grants), give the bounded figure and note the gap.

**5. Related-party transactions.** The most damaging misalignment often sits outside the comp table — value extracted via dealings with entities management/controllers own. From primary disclosure: **counterparties** (US related-person txns in proxy; HK connected txns Ch.14A; A-share 关联交易 + 公告), **type and scale** (sales/purchases, loans, guarantees, asset transfers, leasing, 资金占用 — quantify as % of revenue/assets/profit), **pricing fairness** (arm's length or off-market). **If large** (material, recurring, or off-market) **list explicitly as a misalignment risk** alongside step-3 flags — large RPTs enrich management regardless of incentive design. 资金占用 and guarantees for connected parties are especially serious.

**6. Synthesis.** 2-3 sentences: long-term value creation vs. near-term extraction; do targets reward the right things (vs. peers); adding to or reducing stake; do RPTs undercut the implied alignment. A plain judgment, with evidence.

## Output Format

1. **Compensation table** (execs × cash/equity/total, latest FY + trend).
2. **Structure & targets** — prose + targets sub-table if multi-tier + peer-comparison sub-table.
3. **Incentive read** — what's rewarded + misalignment flags.
4. **Stake bridge table** (exec × horizon × granted/bought+cash/sold+proceeds/net/ending % o/s) for 3/5/10y.
5. **Related-party transactions** — material RPTs (counterparty × type × scale × % rev/assets), large/off-market flagged.
6. **Synthesis** — alignment verdict.

Every figure cites filing, period, URL. Keep granted vs. realized distinct. No buy/sell call — describe alignment, leave the conclusion to the reader.

---

*Version 0.5 — last updated 2026-06-05*
*0.5: condensed for density (removed explanatory prose and duplication; behavior unchanged).*
*0.4: ask output language; cache to ./research-cache/<ticker>/; pause-and-request-manual-download handshake.*
*0.3: A-share data tooling (akshare + tushare).*
*0.2: graceful-degradation fallback.*
