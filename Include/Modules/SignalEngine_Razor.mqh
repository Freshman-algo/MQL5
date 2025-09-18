//+------------------------------------------------------------------+
//| SignalEngine_Razor.mqh – Signals (RSI + EMA + Patterns + Trend) |
//+------------------------------------------------------------------+
#ifndef __SIGNAL_ENGINE_RAZOR_MQH__
#define __SIGNAL_ENGINE_RAZOR_MQH__

#include <Trade/SymbolInfo.mqh>
#include <Modules/CoreDebug_Razor.mqh>

// Optimizer-friendly market mode
enum RazorMarketMode
{
   AUTO = 0,       
   TREND_ONLY = 1,  
   RANGE_OK = 2     
};

// Core Signal Function
int GetRazorSignal(string symbol, ENUM_TIMEFRAMES tf,
                   int rsiPeriod, int rsiBuyLevel, int rsiSellLevel,
                   int emaPeriod, RazorMarketMode marketMode = AUTO)
{
   // --- RSI
   int rsiHandle = iRSI(symbol, tf, rsiPeriod, PRICE_CLOSE);
   double rsiBuf[1];
   if(CopyBuffer(rsiHandle, 0, 0, 1, rsiBuf) != 1) { IndicatorRelease(rsiHandle); return 0; }
   double rsi = rsiBuf[0];
   IndicatorRelease(rsiHandle);
   DebugLogOnce("RSI_Value", "📈 RSI = " + DoubleToString(rsi, 2));

   // --- EMA (value + slope)
   int emaHandle = iMA(symbol, tf, emaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   double emaBuf[2];
   if(CopyBuffer(emaHandle, 0, 0, 2, emaBuf) != 2) { IndicatorRelease(emaHandle); return 0; }
   double emaNow  = emaBuf[0];
   double emaPrev = emaBuf[1];
   IndicatorRelease(emaHandle);
   DebugLogOnce("EMA_Value", "📊 EMA = " + DoubleToString(emaNow, 2));

   double price    = iClose(symbol, tf, 0);
   double slopePts = (emaNow - emaPrev) / _Point;   // slope in points
   bool isUptrend   = (slopePts > 2.0);
   bool isDowntrend = (slopePts < -2.0);
   bool isFlat      = (MathAbs(slopePts) <= 2.0);
   DebugLogOnce("Slope_Pts", "↗/↘ slopePts = " + DoubleToString(slopePts, 1));

   // --- Candles
   double open1  = iOpen(symbol, tf, 1), close1 = iClose(symbol, tf, 1);
   double open2  = iOpen(symbol, tf, 2), close2 = iClose(symbol, tf, 2);
   bool bullEngulf = (close2 < open2 && close1 > open1 && close1 > open2 && open1 < close2);
   bool bearEngulf = (close2 > open2 && close1 < open1 && close1 < open2 && open1 > close2);

   // Conservative fallbacks when engulfing is rare
   bool bullFallback = (close1 > open1) && (price > emaNow) && (rsi <= (rsiBuyLevel  - 5));
   bool bearFallback = (close1 < open1) && (price < emaNow) && (rsi >= (rsiSellLevel + 5));

   // --- Market mode filter
   bool allowBuy  = true;
   bool allowSell = true;

   if(marketMode == TREND_ONLY)
   {
      allowBuy  = isUptrend;
      allowSell = isDowntrend;
   }
   else if(marketMode == AUTO)
   {
      allowBuy  = isUptrend  || isFlat;
      allowSell = isDowntrend|| isFlat;
   }
   // RANGE_OK leaves both = true

   if(!allowBuy)
      DebugLogOnce("Buy_TrendBlocked",  "🛑 BUY blocked: trend not up");
   if(!allowSell)
      DebugLogOnce("Sell_TrendBlocked", "🛑 SELL blocked: trend not down");

   // --- BUY (engulf OR fallback)
   if(allowBuy && price > emaNow && rsi < rsiBuyLevel && (bullEngulf || bullFallback))
   {
      DebugLogOnce(bullEngulf ? "BUY_Engulf" : "BUY_Fallback",
                   "✅ BUY confirmed at " + DoubleToString(price, 2));
      return 1;
   }
   else if(allowBuy)
   {
      if(rsi >= rsiBuyLevel)
         DebugLogOnce("RSI_High_Buy", "❌ BUY blocked: RSI (" + DoubleToString(rsi,1) +
                                      ") >= level " + IntegerToString(rsiBuyLevel));
      if(!(bullEngulf || bullFallback))
         DebugLogOnce("No_Bull_Pattern", "⚠️ BUY blocked: no engulf/fallback");
      if(price <= emaNow)
         DebugLogOnce("Price_Below_EMA_Buy", "⛔ BUY blocked: Price (" + DoubleToString(price,2) +
                                             ") <= EMA (" + DoubleToString(emaNow,2) + ")");
   }

   // --- SELL (engulf OR fallback)
   if(allowSell && price < emaNow && rsi > rsiSellLevel && (bearEngulf || bearFallback))
   {
      DebugLogOnce(bearEngulf ? "SELL_Engulf" : "SELL_Fallback",
                   "✅ SELL confirmed at " + DoubleToString(price, 2));
      return -1;
   }
   else if(allowSell)
   {
      if(rsi <= rsiSellLevel)
         DebugLogOnce("RSI_Low_Sell", "❌ SELL blocked: RSI (" + DoubleToString(rsi,1) +
                                       ") <= level " + IntegerToString(rsiSellLevel));
      if(!(bearEngulf || bearFallback))
         DebugLogOnce("No_Bear_Pattern", "⚠️ SELL blocked: no engulf/fallback");
      if(price >= emaNow)
         DebugLogOnce("Price_Above_EMA_Sell", "⛔ SELL blocked: Price (" + DoubleToString(price,2) +
                                              ") >= EMA (" + DoubleToString(emaNow,2) + ")");
   }

   return 0;
}

#endif // __SIGNAL_ENGINE_RAZOR_MQH__
