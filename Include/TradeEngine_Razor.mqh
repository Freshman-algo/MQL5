
//+------------------------------------------------------------------+
//| TradeEngine_Razor.mqh – Risk + ATR-based Trade Execution         |
//+------------------------------------------------------------------+
#ifndef __TRADEENGINE_RAZOR_MQH__
#define __TRADEENGINE_RAZOR_MQH__

#include <Trade/Trade.mqh>
CTrade trade;

// Inputs
input double RiskPercent = 1.0;  // Risk per trade (% of balance)
input int    ATR_Period  = 14;
input double ATR_Mult_SL = 1.5;
input double ATR_Mult_TP = 2.0;

//+------------------------------------------------------------------+
//| Calculate lot size based on SL distance and risk %               |
//+------------------------------------------------------------------+
double CalculateLot(double slPips)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * (RiskPercent / 100.0);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double pipValue  = tickValue / tickSize;
   double lots = riskAmount / (slPips * pipValue);
   lots = MathMin(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
   lots = MathMax(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Execute trade based on signal                                     |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal)
{
   double atr = iATR(_Symbol, PERIOD_M1, ATR_Period, 0);
   double sl = atr * ATR_Mult_SL;
   double tp = atr * ATR_Mult_TP;
   double price = SymbolInfoDouble(_Symbol, signal == 1 ? SYMBOL_ASK : SYMBOL_BID);
   double lot = CalculateLot(sl);

   // Check if already in position
   if (PositionSelect(_Symbol)) return;

   if (signal == 1)
      trade.Buy(lot, _Symbol, price, price - sl, price + tp, "Razor Buy");
   else if (signal == -1)
      trade.Sell(lot, _Symbol, price, price + sl, price - tp, "Razor Sell");
}

#endif
