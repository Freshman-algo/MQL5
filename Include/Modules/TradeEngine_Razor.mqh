//+------------------------------------------------------------------+
//| TradeEngine_Razor.mqh – Exec, Lot, Trailing, BreakEven          |
//+------------------------------------------------------------------+
#ifndef __TRADEENGINE_RAZOR_MQH__
#define __TRADEENGINE_RAZOR_MQH__

#include <Trade/Trade.mqh>
#include <Modules/CoreDebug_Razor.mqh>
CTrade trade;

double GetLotSize(bool useFixed, double fixedLot, double riskPercent, double slInPrice,
                  double maxLot, double minLot)
{
   if(useFixed) return MathMin(MathMax(fixedLot, minLot), maxLot);
   if(slInPrice<=0) return MathMax(minLot, 0.01);

   double balance    = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * (riskPercent/100.0);
   double tickValue  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize<=0) tickSize=_Point;
   double pipValue   = tickValue / tickSize;
   double lot        = riskAmount / (slInPrice * pipValue);
   return NormalizeDouble(MathMin(MathMax(lot, minLot), maxLot), 2);
}

void ExecuteTrade(int signal, bool useFixedLot, double fixedLotSize, double riskPercent,
                  int atrPeriod, double atrMultSL, double atrMultTP,
                  double maxLot, double minLot,
                  bool enableTrailing, double trailStart, double trailStep,
                  bool useBE, double BE_trigger, double BE_offset)
{
   int atrHandle = iATR(_Symbol, PERIOD_M1, atrPeriod);
   double a[1]; if(CopyBuffer(atrHandle,0,0,1,a)!=1){ IndicatorRelease(atrHandle); return; }
   double atr=a[0]; IndicatorRelease(atrHandle);

   double slPrice = atr*atrMultSL;
   double tpPrice = atr*atrMultTP;

   double lot   = GetLotSize(useFixedLot, fixedLotSize, riskPercent, slPrice, maxLot, minLot);
   double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(PositionSelect(_Symbol)) return;

   double entry = (signal==1)? ask : bid;
   double sl    = (signal==1)? (entry - slPrice) : (entry + slPrice);
   double tp    = (signal==1)? (entry + tpPrice) : (entry - tpPrice);

   bool ok = (signal==1) ? trade.Buy(lot,_Symbol,entry,sl,tp,"Razor Buy")
                         : trade.Sell(lot,_Symbol,entry,sl,tp,"Razor Sell");
   if(!ok) { DebugLogOnce("Order_Fail","❌ OrderSend failed"); return; }

   DebugLogOnce("Order_OK","🟢 Order placed lot="+DoubleToString(lot,2));
}

// called EVERY tick from main (so trailing/BE continue)
void ManageOpenTrade(bool trailing, double trailStartPips, double trailStepPips,
                     bool useBE, double beTrigPips, double beOffPips)
{
   if(!PositionSelect(_Symbol)) return;

   ulong  ticket = PositionGetInteger(POSITION_TICKET);
   int    type   = (int)PositionGetInteger(POSITION_TYPE);
   double entry  = PositionGetDouble(POSITION_PRICE_OPEN);
   double sl     = PositionGetDouble(POSITION_SL);
   double tp     = PositionGetDouble(POSITION_TP);
   double price  = (type==POSITION_TYPE_BUY)? SymbolInfoDouble(_Symbol,SYMBOL_BID)
                                            : SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   double onePip = _Point*10.0; // consistent with previous Razor usage
   double dist   = MathAbs(price-entry);

   // ---- BreakEven
   if(useBE && dist >= beTrigPips*onePip)
   {
      double newSL = (type==POSITION_TYPE_BUY)? (entry + beOffPips*onePip)
                                              : (entry - beOffPips*onePip);
      bool better  = (type==POSITION_TYPE_BUY)? (newSL>sl) : (newSL<sl || sl==0.0);
      if(better)
      {
         if(trade.PositionModify(ticket, newSL, tp))
            DebugLogOnce("BE_OK","🔐 BE set SL="+DoubleToString(newSL,_Digits));
         else
            DebugLogOnce("BE_FAIL","❌ BE modify failed");
      }
   }

   // ---- Trailing
   if(trailing && dist >= trailStartPips*onePip)
   {
      double newSL = (type==POSITION_TYPE_BUY)? (price - trailStepPips*onePip)
                                              : (price + trailStepPips*onePip);
      bool better  = (type==POSITION_TYPE_BUY)? (newSL>sl) : (newSL<sl || sl==0.0);
      if(better)
      {
         if(trade.PositionModify(ticket, newSL, tp))
            DebugLogOnce("TRAIL_OK","🔁 SL="+DoubleToString(newSL,_Digits));
         else
            DebugLogOnce("TRAIL_FAIL","❌ Trail modify failed");
      }
   }
}

#endif
