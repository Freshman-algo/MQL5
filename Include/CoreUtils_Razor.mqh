
//+------------------------------------------------------------------+
//| CoreUtils_Razor.mqh – Spread & Session Filters                   |
//+------------------------------------------------------------------+
#ifndef __COREUTILS_RAZOR_MQH__
#define __COREUTILS_RAZOR_MQH__

// Inputs
input int StartHour = 7;
input int EndHour   = 22;
input double MaxSpread = 30;

// Check session time
bool IsTradingTime()
{
   int hour = TimeHour(TimeCurrent());
   return (hour >= StartHour && hour < EndHour);
}

// Check spread filter
bool IsSpreadAcceptable()
{
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   return (spread <= MaxSpread);
}

#endif
