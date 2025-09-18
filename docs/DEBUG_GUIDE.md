# Debug Guide (CoreDebug_Razor)
- Switch on: input `ShowDebug=true`
- Logs print once per tag (non-spam) until `DebugReset(...)` / `DebugResetAll()`.

## Common Tags
- Pipeline blocks: `EA_OFF`, `Session_Blocked`, `Spread_Blocked`, `MaxTrades_Blocked`
- Signal values: `RSI_Value`, `EMA_Value`
- Confirmation: `BUY_Confirmed`, `SELL_Confirmed`
- Buy blocks: `RSI_High_Buy`, `No_Bull_Engulf`, `Price_Below_EMA_Buy`, `Buy_TrendBlocked`
- Sell blocks: `RSI_Low_Sell`, `No_Bear_Engulf`, `Price_Above_EMA_Sell`, `Sell_TrendBlocked`
- Trailing/BE: `Trail_BUY_Mod`, `Trail_SELL_Mod`, `BE_BUY`, `BE_SELL`

**Tip:** Do not call `DebugResetAll()` every tick unless you truly want new messages. Prefer resetting only when a state meaningfully changes.
