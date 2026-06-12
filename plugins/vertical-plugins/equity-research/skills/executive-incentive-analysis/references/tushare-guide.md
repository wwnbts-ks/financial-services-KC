# Tushare Pro reference (for A-share financial/market data)

Read this when you need to pull A-share financials, market cap, index weights, or macro via tushare. Tushare = structured A-share numbers (no narrative). Token at `~/.config/tushare/token`. Pair with akshare (insider transactions) and cninfo (filings/announcements).

## Access

Python SDK (preferred):
```python
import os, tushare as ts
ts.set_token(open(os.path.expanduser("~/.config/tushare/token")).read().strip())
pro = ts.pro_api()
df = pro.daily(ts_code="600519.SH", start_date="20250101", end_date="20260101")  # returns a DataFrame
```

HTTP fallback: `POST http://api.tushare.pro` (note: http, not https), body `{"api_name","token","params","fields"}`; response is `data.fields` + `data.items` (column names + 2-D array), `code=0` = success.

## Endpoints by task

| Need | Endpoint |
| --- | --- |
| Stock list / industry | `stock_basic` |
| Trading calendar | `trade_cal` |
| Daily OHLCV | `daily` |
| Adjustment factor (for after-adj prices) | `adj_factor` |
| Daily metrics (turnover, **PE, PB, market cap**) | `daily_basic` |
| Minute bars | `stk_mins` |
| Index daily / weights | `index_daily` / `index_weight` |
| Income statement | `income` |
| Balance sheet | `balancesheet` |
| Cash flow | `cashflow` |
| Financial ratios (ROE, margin, leverage) | `fina_indicator` |
| Northbound top-10 | `hsgt_top10` |
| Macro | `shibor`, `cn_cpi`, `cn_gdp`, `cn_ppi`, `cn_pmi`, `cn_sf` |

**Not available on this token:** `anns_d` (announcement text) — gated behind higher credit. For 减持公告 / 股权激励考核办法 text, use cninfo or akshare, not tushare.

## After-adjusted price (needed for the 10y post-sale stock-move analysis)
```python
df = pro.daily(ts_code=code, start_date=s, end_date=e)
adj = pro.adj_factor(ts_code=code)
df = df.merge(adj[["trade_date","adj_factor"]], on="trade_date")
df["hfq_close"] = df["close"] * df["adj_factor"]   # back-adjusted close
```

## Gotchas (tushare-specific)
- **ts_code format**: `600519.SH` / `000001.SZ` / `xxxxxx.BJ` — uppercase, with exchange suffix. Wrong format → empty result.
- **Date format**: daily is `YYYYMMDD`; minute is `YYYY-MM-DD HH:MM:SS`. Don't mix.
- **40202 rate limit**: free/low-credit tokens are throttled per minute. Batch scripts: add `time.sleep(0.3)` between calls.
- **40203 no permission**: credit too low for that endpoint — check the endpoint's credit requirement.
- **40101 wrong api name**: endpoint renamed/typo — verify at tushare.pro/document/2.
- **Returned fields may differ from docs** — trust the live `fields`, not the doc.
- **Financials lag**: post-disclosure ~T+1; for critical dates reconcile against cninfo.
- **US/HK depth is weak** — tushare is A-share-first; use FactSet/S&P for US, cninfo/HKEXnews for HK.

## Snapshot template (one-shot fundamentals pull)
```python
def snapshot(ts_code, start="20240101"):
    from datetime import date
    end = date.today().strftime("%Y%m%d")
    return {
        "daily_basic": pro.daily_basic(ts_code=ts_code, trade_date=end).to_dict("records"),
        "income":     pro.income(ts_code=ts_code, start_date=start, end_date=end).to_dict("records"),
        "balance":    pro.balancesheet(ts_code=ts_code, start_date=start, end_date=end).to_dict("records"),
        "cashflow":   pro.cashflow(ts_code=ts_code, start_date=start, end_date=end).to_dict("records"),
        "indicator":  pro.fina_indicator(ts_code=ts_code, start_date=start, end_date=end).to_dict("records"),
    }
```

Docs: tushare.pro/document/2
