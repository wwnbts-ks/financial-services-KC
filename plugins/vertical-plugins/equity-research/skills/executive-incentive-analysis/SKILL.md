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
| **HK** | Annual report: emoluments note, share-option-scheme section + year-end directors' interests snapshot (s.352); option/award scheme circulars (HKEXnews) | **DI/DION system — `di.hkex.com.hk`** (Disclosure of Interests, separate portal from HKEXnews): per-dealing director/CE forms (3A/3B, within 3 business days) + substantial-shareholder forms (1/2), dated buy/sell records, pledges — the source for the step-4 bridge |
| **A-share** | 年报「董监高」薪酬章节; 股权激励计划草案/考核办法 (cninfo) | 减持/增持公告、权益变动报告书、大宗交易、股份质押公告 (交易所 + cninfo) |

For dual-listed/VIE names, reconcile across regimes and flag where disclosures differ.

**A-share tooling** (faster path to the same primary data, never a substitute for citing the filing): use **akshare-one MCP** for 高管增减持/持股变动 (primary tool for the step-4 bridge); use the **tushare SDK** for shares outstanding, market cap, and financial base (income/balance sheet/ratios, after-adjusted prices). For tushare endpoints, the after-adjusted-price recipe, rate-limit/format gotchas, and a one-shot snapshot template, read `references/tushare-guide.md`. tushare can't supply 考核办法 or 减持公告 text (gated `anns_d`) — those come from cninfo or akshare.

**Setup (`config.json`).** Read `config.json` at the start of a run for: `tushare_token_path`, `cache_dir`, `output_dir` (where the final report is written — see Output Format), `filing_proxy` (the local proxy port to route filing downloads through — required for cninfo, see Gotchas), `default_output_language` (skip the step-0 question if set), `local_filings_dirs` (per-ticker local folder of the user's own filings — check it before any fetch, see step 0.5), and `default_peer_sets`. For peers: an **empty** array `[]` for the ticker means "not set yet" → derive, confirm with the user, then **write the confirmed peers back into `config.json`** so the next run skips the derivation + re-search; a **non-empty** array is used as-is. If a needed value is absent, ask the user.

**Local cache (cache-first is mandatory — this is the biggest speed win):**
- Save every retrieved filing to `cache_dir` (default `./research-cache/<ticker>/`); also where the user drops manual downloads.
- **Before any download, read from disk first — both the user's `local_filings_dirs` folder (step 0.5) and `cache_dir`.** Only fetch what is genuinely absent from both — never re-download a filing the user already has locally or that's already in the cache.
- **Use `./fetch_filing.sh <ticker> <url> [basename]` for every filing download** (in this skill's dir). It is cache-first, routes through `filing_proxy`, retries, sets a browser UA, and converts the PDF to `.txt` once. Do **not** hand-roll `curl`/`pdftotext` retry loops — that is exactly what made past runs stall 7–18 min per file.
- **Don't load whole annual-report PDFs into context.** After conversion, `grep`/extract only the relevant sections (薪酬章节 / 股权激励计划 / 考核办法 / 减持公告 / 关联交易) into a small `<ticker>/_extract_*.md` and read those. Dumping full filings is what pushed past runs to 160K-token context and made every later turn slow.

## Execution Discipline (keep it fast)

Past runs averaged 1.5–6 hours; the wall-clock went to three avoidable places. Hold to these:

- **Locate filings by direct source, not WebSearch.** For A-share insider/holding data use **akshare-one MCP** and **tushare** directly (structured, fast) — don't search the web for it. For a specific filing PDF, go to the known disclosure host (cninfo / HKEXnews / EDGAR) and construct the URL; reserve WebSearch for the rare case with no structured source and no constructable URL. A single open-ended WebSearch for "find the annual report" has cost 30+ min — that is the failure mode to avoid.
- **Limit subagents.** A single-company incentive analysis does **not** need a fan-out of one subagent per requirement — that pattern cost ~16 min per subagent and dominated total time. Do the data pulls and reasoning inline. Spin up **at most one** scoped subagent, and only for a genuinely separable, search-heavy chunk (e.g. building a peer's structure from scratch). Never run parallel subagents for the same company's sub-sections.
- **Exhaust the cache and structured tools before fetching**, per the Local cache rules above.

## When a Primary Source Can't Be Reached

A-share/HK filings often can't be fetched (blocked PDFs, timeouts, TLS/proxy errors; akshare/tushare don't cover 考核办法 or full 减持公告 text). For a **core** input (annual report, incentive plan, 减持/增持 disclosure), in order:

1. **Check local first, then alternate tools** — look in the user's `local_filings_dirs` folder (step 0.5) and `cache_dir` before fetching; then `fetch_filing.sh` (proxy-routed, retries) for the PDF; akshare for the same data point, tushare for series data. Exhaust local + automated paths first.
2. **Still missing → STOP and ask the user.** Do not fabricate or substitute a secondary number for a core input. State: **what's missing** (exact document, e.g. "三花智控 2024年报"), **where to get it** (cninfo 公告页 / HKEXnews / EDGAR + search term), **where to put it** (`./research-cache/<ticker>/`, full path). Ask them to reply when done.
3. **Resume** from the pause point when the user confirms — read from the cache folder, don't restart.
4. **Labeled partial, last resort only** (user declines / file doesn't exist): mark each figure **[primary]** or **[secondary, unverified]**, leave blocked sections marked missing not guessed, end with a "Primary sources to confirm" checklist.

The stall is deliberate and informative — never silent, never a fabricated fill.

## Workflow

**0. Output language.** If `config.json` sets `default_output_language`, use it. Otherwise ask: 中文为主还是英文为主. Keep proper nouns, filing names, financial terms in original form either way (减持公告, DEF 14A, RSU). Don't re-ask within a run.

**0.5 Local source folder — check before any fetch (biggest time saver).** Before fetching anything online, find out whether the user already has this company's filings/transcripts on disk:
- If `config.json`'s `local_filings_dirs` has a path for this ticker, use it (confirm it still exists; don't re-ask). Otherwise **ask once**: "这家公司的财报/公告/transcript 有没有已经存在本地某个文件夹?有的话给我路径(没有就直接说没有)。" If none, proceed with cache + online fetch as before.
- Given a folder: **list it recursively, index the files, and map each to a requirement** — 年报/中报 → Req 1/2 (holdings, comp, option scheme); 股权激励计划/考核办法 → Req 2 (targets); 减持/增持公告 · DI forms (Form 3A/3B etc.) → Req 4 (stake bridge); 关联交易公告 → Req 5. **Read these in place first**, extracting only the needed sections into `cache_dir/<ticker>/_extract_*.md` as usual (don't copy whole PDFs around).
- **Then fetch only the gap.** Diff required-docs against what the folder supplies; go online (structured tools → `fetch_filing.sh`) only for what's genuinely missing, per Execution Discipline. Note explicitly which inputs came from the local folder vs. were fetched.
- **Write the confirmed path back into `config.json` `local_filings_dirs[<ticker>]`** so the next run uses it without asking (same self-populating pattern as `default_peer_sets`).
- Treat folder files as **primary** sources (they are the user's own downloads of filings) — still cite filing / period / URL where determinable; if a local file's provenance is unclear, flag it rather than assume. Paths may contain spaces / non-ASCII — always quote in shell.

**1. Define key management.** Executive management only — executive directors + senior management (US: NEOs; A-share: 执行董事 + 高管). **Exclude** non-executive/independent directors and A-share 监事. State who is in scope.

**2. Compensation summary (Req 1).** Per executive, latest FY + 1-2 prior for trend, as one table: cash (base + bonus); equity (grant-date fair value of options/RSUs/PSUs); other (pension, perks); total; cash-vs-equity mix. Keep **granted** (fair value at grant) distinct from **realized** — conflating them is the most common error.

**3. Equity-incentive structure & targets (Req 2)** — the analytical core:
- **Instrument**: options/RSU/PSU/restricted; strike vs. grant-date price.
- **Vesting**: schedule, cliff, total period (longer = better alignment).
- **Performance conditions**: actual metrics and thresholds, quoted precisely (revenue CAGR ≥ X%, ROE ≥ Y%, relative TSR). For A-share, the 业绩考核 grid (公司+个人) and 解锁/归属比例 per tier.
- **Peer comparison**: pull the equivalent structure for 2-3 closest peers; compare pay mix, metric type, and threshold toughness. Are the targets stretch or soft relative to what peers must hit? Cite each peer's disclosure.
- **Difficulty of achievement** — the central question for any ESOP: is the target something management must genuinely perform to hit, or is it form-over-substance, set to be cleared with near-certainty? Pressure-test the threshold against history and construction, don't take it at face value. Specifically interrogate **relative/benchmark-based targets**, where the rigging usually hides: if a target is "ROE in the 80th percentile of peer group X," examine group X itself — a high percentile against a deliberately weak or loss-making peer set is a trivially low absolute bar dressed up as demanding (e.g. requiring 80th-percentile ROE among peers whose ROE is mostly poor or negative). Also check: targets set below the company's own recent actuals or trailing trend; thresholds a flat extrapolation already clears; "growth" targets achievable by inertia. State whether each target is a real hurdle or cosmetic, and show the arithmetic.
- **Incentive read**: what behavior do the metrics reward? Flag misalignment — growth rewarded regardless of margin/ROIC; absolute (not relative) TSR in a rising market; soft thresholds (esp. vs. peers); rigged benchmark construction; repricing history; large unconditional time-vested grants.

**4. Equity stake bridge — 3/5/10 years (Req 3).** Per executive and aggregate, for each horizon (three horizons separate recent behavior from lifetime pattern):
- **Granted** (company-funded), **Bought** (own cash on market + outlay — strongest alignment signal), **Sold** (shares + gross proceeds; split discretionary vs. 10b5-1), **Net change** + ending stake (shares and % o/s).
- Also: buys/sells as % of holdings at the time; **pledged shares** (material for A-share/HK founders — near-monetization without a reportable sale, flag it); lockups, secondary placements, timing vs. price highs.
- Frame as company-funded (granted) vs. own-cash (bought) vs. outflow (sold): a stake growing only via grants while steadily selling ≠ buying with own money.
- **Selling against the regulatory ceiling** — for each sale, check whether it is sized at or near the maximum the rules allow, not just its absolute size. A-share insiders face caps (e.g. ≤25% of holdings reduced per year, plus 集中竞价/大宗交易 quarterly limits); a sale that maxes out the permitted amount signals management cashing out as fast as the framework permits — a stronger negative than the raw RMB figure. (Example: 三花智控 management's reduction in Mar 2026 was sized to the annual ≤25%-of-holdings cap — i.e. selling the maximum allowed.) State, per sale, whether it is at/near the cap and which limit binds.
- **Post-sale outcome history (10y)** — for each material reduction over the past 10 years, look at what happened in the ~6 months *after*: did the stock underperform, and did the business deteriorate (guidance cuts, margin/revenue weakness, negative news)? A repeated pattern of insiders selling shortly before negative developments is a serious signal that they sell on private information. Tabulate each historic sale → subsequent 6-month stock move and business change, and note whether a consistent pattern exists.
- Where disclosure is incomplete (大宗交易 lagged price, pre-IPO grants), give the bounded figure and note the gap.

**5. Related-party transactions.** The most damaging misalignment often sits outside the comp table — value extracted via dealings with entities management/controllers own. From primary disclosure: **counterparties** (US related-person txns in proxy; HK connected txns Ch.14A; A-share 关联交易 + 公告), **type and scale** (sales/purchases, loans, guarantees, asset transfers, leasing, 资金占用 — quantify as % of revenue/assets/profit), **pricing fairness** (arm's length or off-market). **If large** (material, recurring, or off-market) **list explicitly as a misalignment risk** alongside step-3 flags — large RPTs enrich management regardless of incentive design. 资金占用 and guarantees for connected parties are especially serious.

**6. Synthesis.** 2-3 sentences: long-term value creation vs. near-term extraction; do targets reward the right things (vs. peers); adding to or reducing stake; do RPTs undercut the implied alignment. A plain judgment, with evidence.

## Output Format

**Write the final report to disk, not just chat.** At the end of a run, save the full report as `<output_dir>/<ticker>-incentives-<YYYY-MM-DD>.md` — expand `output_dir` from `config.json` (default `~/Library/CloudStorage/OneDrive-个人/Kaisi work/CC output/executive-incentive-analysis/<ticker>/`, substituting `<ticker>`), create the folder if missing, then also render it in chat. The path contains spaces and non-ASCII — always quote it in shell. This is the deliverable folder; keep it separate from `cache_dir` (raw filings, extracts, scratch scripts stay in the cache, never in `output_dir`). If `output_dir` is absent from config, ask the user where to write before saving.

The report sections:

1. **Compensation table** (execs × cash/equity/total, latest FY + trend).
2. **Structure & targets** — prose + targets sub-table if multi-tier + peer-comparison sub-table.
3. **Incentive read** — what's rewarded + misalignment flags.
4. **Stake bridge table** (exec × horizon × granted/bought+cash/sold+proceeds/net/ending % o/s) for 3/5/10y, with per-sale cap-check (at/near regulatory ceiling?) and a 10-year post-sale outcome column (subsequent 6-month stock/business change).
5. **Related-party transactions** — material RPTs (counterparty × type × scale × % rev/assets), large/off-market flagged.
6. **Synthesis** — alignment verdict.

Every figure cites filing, period, URL. Keep granted vs. realized distinct. No buy/sell call — describe alignment, leave the conclusion to the reader.

## Gotchas

Hard-won failure points when running this skill on A-share / HK names. Check here first when data retrieval misbehaves.

- **HK director 增减持 — the annual report and the DI system disclose DIFFERENT things; use both.** The **annual report** (Report of the Directors, Listing Rules Appendix D2 / Practice Note 5) gives only a **year-end snapshot** of each director's/CE's aggregate long/short interest (from the SFO s.352 register), plus **share-option-scheme movements during the year** (granted / exercised / lapsed / outstanding, with exercise price) — it does **not** itemize individual dealings. The **transaction-by-transaction record** — each buy / sell / pledge with its **date and price/consideration** — lives only in the **Disclosure of Interests (DI / DION) system at `di.hkex.com.hk`** (separate portal from HKEXnews), where directors/CEs must file **Form 3A/3B within 3 business days** of each dealing (substantial shareholders ≥5% file Form 1/2 on threshold and 1%-level changes). So: take the year-end holding and option structure from the annual report (Req 1/2), but build the **step-4 stake bridge** (per-sale timing, proceeds, % of holdings, vs. price highs) from the DI filings — the annual report won't date the trades.
- **HK management stake may have moved since the last report — query the SDI system up to *today*, not just the report date.** A periodic report (annual / interim) freezes each director's/CE's holding at the **period-end only**; by the time you analyze — often weeks to months later — they may have dealt again, and those **post-period** dealings appear **only** in the **Shareholding Disclosure of Interests (SDI) system, i.e. the same `di.hkex.com.hk` DI/DION portal** (not a separate site), where each dealing is filed (Form 3A/3B) within **3 business days**. So for the step-4 bridge, never treat the report's period-end holding as current: search the DI system for every director/CE dealing **dated from the report's period-end through the analysis date**, carry the report's closing position forward over them, and **state the as-of date** of the holding you report. Use the per-stock search or "Search of daily summaries" at `di.hkex.com.hk`.
- **cninfo fetch fails with a TLS/cert error, but `curl` to the same host works** — the host is being resolved to a fake-IP (198.18.x.x) by a local proxy's fake-IP mode, and the fetch layer isn't using the proxy. **Use `fetch_filing.sh`**, which routes through `filing_proxy` from `config.json` (default `http://127.0.0.1:1082`) — it handles this. If fetching by hand, set `HTTPS_PROXY`/`HTTP_PROXY` to that port. Not a real certificate problem.
- **`api.tushare.pro` is http, not https** — proxy/cert tooling that assumes https will mishandle it.
- **tushare `anns_d` returns no permission (40203)** — announcement text is gated. 减持公告 / 股权激励考核办法 text must come from cninfo or akshare, never assume tushare has it.
- **akshare-one MCP shows 0 servers / won't start in the desktop app** — the GUI's PATH often lacks `/opt/homebrew/bin`, so `uvx` isn't found. Use the absolute path to `uvx` in `.mcp.json`. First launch also pulls deps (slow, ~1–2 min) — not a hang.
- **akshare covers insider transactions but not full announcement text** — for 考核办法 detail and exact 减持 terms, go to the cninfo PDF; akshare gives the structured transaction record, not the prose.
- **A-share ts_code must be `600519.SH` / `000001.SZ` / `xxxxxx.BJ`** (uppercase, exchange suffix) or tushare/akshare return empty.
- **大宗交易 (block-trade) price/proceeds disclosure lags** — for recent reductions the RMB proceeds may not be clean yet; give the bounded figure and flag the gap rather than guessing.
- **Regulatory-cap check needs the rule in force at the time** — A-share reduction limits (e.g. ≤25%/yr, quarterly 集中竞价/大宗 caps) have changed over the years; confirm the cap applicable to the sale's date before calling it "顶格".
- **Financials lag disclosure (~T+1)** — near a reporting date, reconcile tushare numbers against the cninfo filing.

## Files

- `fetch_filing.sh` — proxy-routed, cache-first filing downloader + PDF→text converter. Use for every filing fetch: `./fetch_filing.sh <ticker> <url> [basename]`.
- `references/tushare-guide.md` — tushare endpoints, after-adjusted-price recipe, gotchas, snapshot template. Read when pulling A-share financials/prices.
- `config.json` — token path, cache dir, output dir, filing proxy, default language, default peer sets. Read at start of run.

---

*Version 0.9 — last updated 2026-06-19*
*0.9: local-folder-first — added workflow step 0.5: before any online fetch, check whether the user has a local folder of the company's filings/transcripts (new `local_filings_dirs` config key, self-populating per ticker like peer sets); index it, map files to requirements, read in place, and fetch only the gap. Threaded the local folder into the Local-cache rule and the "can't reach a source" fallback as the first place to look.*
*0.8.2: HK staleness gap — added a gotcha that a periodic report freezes each director's/CE's holding at the period-end only; post-period dealings live solely in the SDI / `di.hkex.com.hk` DI/DION system (Form 3A/3B, 3 business days), so the step-4 bridge must query the DI system from the report's period-end through the analysis date and state the holding's as-of date.*
*0.8.1: HK insider source — clarified the two-tier HK regime: the annual report (App D2 / PN5) carries only the year-end s.352 interests snapshot + option-scheme movements, while the transaction-by-transaction dated buy/sell/pledge records (Form 3A/3B, 3 business days) live in the Disclosure of Interests (DI/DION) system `di.hkex.com.hk` — use the annual report for Req 1/2 holdings/structure and the DI filings for the step-4 stake bridge.*
*0.8: performance + output — added `fetch_filing.sh` (proxy-routed, cache-first download + PDF→text) to replace hand-rolled retry loops; mandated cache-first + section-extraction (no whole-PDF context dumps); added "Execution Discipline" (locate via akshare/tushare not WebSearch; cap subagent fan-out); config.json gains `filing_proxy`, `output_dir` (final report written to a dedicated deliverable folder, separate from the cache), `default_output_language` defaulted, and self-populating peer-set slots for high-frequency tickers.*
*0.7: folder structure — split tushare detail to references/tushare-guide.md, added config.json (token/cache/language/peers), added Gotchas section (proxy/cert, tushare/akshare boundaries, ts_code, block-trade lag, cap-rule timing).*
*0.6: selling analysis — flag sales sized to the regulatory cap, and 10y post-sale outcome pattern (6-month stock/business change after each reduction); ESOP analysis — interrogate difficulty of achievement, esp. rigged peer-benchmark targets.*
*0.5: condensed for density (removed explanatory prose and duplication; behavior unchanged).*
*0.4: ask output language; cache to ./research-cache/<ticker>/; pause-and-request-manual-download handshake.*
*0.3: A-share data tooling (akshare + tushare).*
*0.2: graceful-degradation fallback.*
