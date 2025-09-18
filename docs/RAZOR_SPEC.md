# Razor Spec (quick)
**Inputs (main EA):**
- MarketMode: `"auto"` / `"trend_only"` / `"range_ok"`
- RSI_Period, RSI_BuyLevel, RSI_SellLevel
- EMA_Period (signal + slope for trend)
- UseFixedLot, FixedLotSize **or** RiskPercent
- ATR_Period, ATR_Mult_SL, ATR_Mult_TP
- EnableTrailingStop, TrailingStartPips, TrailingStepPips
- UseBreakEven, BE_TriggerPips, BE_OffsetPips
- StartHour, EndHour, MaxSpread, ShowDebug

**Modules:**
- `SignalEngine_Razor.mqh`: GetRazorSignal() → RSI + EMA + Engulf + Trend filter (EMA slope)
- `TradeEngine_Razor.mqh`: lot sizing, ATR SL/TP, trailing, break-even
- `CoreUtils_Razor.mqh`: IsTradingTime(), IsSpreadAcceptable()
- `CoreDebug_Razor.mqh`: DebugLogOnce(tag, msg), DebugReset, DebugResetAll (used carefully)
- `LightPanel_Razor.mqh`: Vertical panel: EA status, session, spread, PnL, W/L, trades, **Signal**

**Rules:**
- BUY: `rsi < rsiBuyLevel` AND bullish engulf AND `price > ema` AND trend (per MarketMode)
- SELL: `rsi > rsiSellLevel` AND bearish engulf AND `price < ema` AND trend (per MarketMode)
