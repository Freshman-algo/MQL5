//+------------------------------------------------------------------+
//| CoreUtils_Razor.mqh – Time & Spread filters                     |
//+------------------------------------------------------------------+
#ifndef __COREUTILS_RAZOR_MQH__
#define __COREUTILS_RAZOR_MQH__

bool IsTradingTime(const int startHour, const int endHour)
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   const int h = dt.hour;
   const bool ok = (h>=startHour && h<endHour);
   DebugLogOnce(ok ? "Sess_OK" : "Sess_BAD",
                ok ? "🟢 Trading hours ["+IntegerToString(h)+":00]"
                   : "🔒 Not trading hours ["+IntegerToString(h)+":00]");
   return ok;
}

bool IsSpreadAcceptable(const double maxSpread)
{
   long sp = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(sp <= (long)maxSpread)
   {
      DebugLogOnce("Spread_OK",  "✅ Spread "+IntegerToString(sp));
      return true;
   }
   DebugLogOnce("Spread_BAD", "⚠️ Spread "+IntegerToString(sp)+" > Max "+DoubleToString(maxSpread,0));
   return false;
}

#endif
