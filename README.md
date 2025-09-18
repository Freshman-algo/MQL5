# Mark21 Razor — Scalper EA (MT5)

A fast, **trend-aware** scalper optimized for **small ZAR accounts**.

## Core Features
- **Signal**: RSI + EMA + Engulfing. `MarketMode`: `"auto"`, `"trend_only"`, `"range_ok"` (EMA slope–based)
- **Execution**: Fixed lot **or** risk% lot; ATR SL/TP
- **Protection**: Session filter, spread guard, max open trades
- **Management**: Trailing stop (positive inputs), Break-even (toggle + trigger/offset)
- **DX**: Non-spam `CoreDebug` logger; **LightPanel** (vertical, shows signal/status)

## Layout

MQL5/
|-- Experts/
|   `-- Mark21_Razor.mq5
`-- Include/
    `-- Modules/
        |-- SignalEngine_Razor.mqh
        |-- TradeEngine_Razor.mqh
        |-- CoreUtils_Razor.mqh
        |-- CoreDebug_Razor.mqh
        `-- LightPanel_Razor.mqh

## Build
1. Open `Experts/Mark21_Razor.mq5` in **MetaEditor**
2. Compile (F7)
3. Attach EA in MT5; check **Experts** tab for clean startup logs

## Backtest (quick)
- Start with **Open prices only** → then **Every tick** to confirm
- Compare `MarketMode="auto"`, `"trend_only"`, `"range_ok"`
- Tune: `ATR_Mult_SL/TP`, `TrailingStart/Step`, RSI levels, EMA period
