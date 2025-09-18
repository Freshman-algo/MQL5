//+------------------------------------------------------------------+
//|                     Mark21 Razor Scalper EA                      |
//|      Author: Uchenna Lesedi Manyaka — 2025                      |
//+------------------------------------------------------------------+
#property strict
#property version   "1.02"

#include <Modules/SignalEngine_Razor.mqh>
#include <Modules/TradeEngine_Razor.mqh>
#include <Modules/CoreUtils_Razor.mqh>
#include <Modules/LightPanel_Razor.mqh>
#include <Modules/TesterCore_Razor.mqh>


//---------------- Optimizer-friendly market mode -------------------

//---------------- Inputs -------------------------------------------
input group "Switches"
input bool   EA_ON               = true;
input bool   ShowDebug           = true;

input group "Signal Engine"
input int    RSI_Period          = 14;
input int    RSI_BuyLevel        = 30;
input int    RSI_SellLevel       = 70;
input int    EMA_Period          = 50;
input RazorMarketMode MarketMode = AUTO;

input group "Risk & Lots"
input bool   UseFixedLot         = true;
input double FixedLotSize        = 0.1;
input double RiskPercent         = 1.0;
input double MaxLotSize          = 0.10;
input double MinLotSize          = 0.1;
input int    MaxOpenTrades       = 2;

input group "Stops & Targets (ATR)"
input int    ATR_Period          = 14;
input double ATR_Mult_SL         = 1.8;
input double ATR_Mult_TP         = 2.4;

input group "Trade Management"
input bool   EnableTrailingStop  = true;
input double TrailingStartPips   = 20;
input double TrailingStepPips    = 10;
input bool   UseBreakEven        = true;
input double BE_TriggerPips      = 25;
input double BE_OffsetPips       = 2;

input group "Session & Spread"
input int    StartHour           = 7;
input int    EndHour             = 22;
input double MaxSpread           = 100;

input group "Optimization Fitness"
input bool    UseCustomFitness      = true;   
input int     MinTrades             = 150;      
input double  MaxDDPct              = 35.0;   
input bool    LogPassesToCSV        = true;   
input string  LogFileBase           = "Razor_Opt";
input int     KeepTopN              = 10;      


//---------------- Stats / Panel -----------------------------------
RazorPanel panel;
double     netProfit    = 0;
int        wins         = 0;
int        losses       = 0;
int        totalTrades  = 0;

//---------------- Helpers -----------------------------------------
int CountOpenTrades(string symbol)
{
   int total = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionGetSymbol(i) == symbol)
         total++;
   return total;
}

int OnInit()
{
   panel = RazorPanel("RazorPanel", 10, 20);
   Print("✅ Mark21 Razor initialized.");
   return INIT_SUCCEEDED;
}

void OnTick()
{
   // 1) Blockers
   if(!EA_ON)                         { DebugLogOnce("EA_OFF", "🟥 EA disabled"); return; }
   if(!IsTradingTime(StartHour,EndHour)) { DebugLogOnce("Time_Filter","🕒 Outside trading hours"); return; }
   if(!IsSpreadAcceptable(MaxSpread)) { DebugLogOnce("Spread_Block","⚠️ Spread too high"); return; }
   if(CountOpenTrades(_Symbol)>=MaxOpenTrades){ DebugLogOnce("Max_Trades","⚠️ Max open trades reached"); return; }

   // 2) Signal
   int signal = GetRazorSignal(_Symbol, PERIOD_M1, RSI_Period, RSI_BuyLevel, RSI_SellLevel, EMA_Period, MarketMode);
   string signalText = (signal==1) ? "📈 BUY" : (signal==-1) ? "📉 SELL" : "❌ No Signal";

   // 3) Execute once if no open position on symbol
   if(signal!=0 && !PositionSelect(_Symbol))
   {
      double balanceBefore = AccountInfoDouble(ACCOUNT_BALANCE);

      ExecuteTrade(signal, UseFixedLot, FixedLotSize, RiskPercent,
                   ATR_Period, ATR_Mult_SL, ATR_Mult_TP,
                   MaxLotSize, MinLotSize,
                   EnableTrailingStop, TrailingStartPips, TrailingStepPips,
                   UseBreakEven, BE_TriggerPips, BE_OffsetPips);

      double delta = AccountInfoDouble(ACCOUNT_BALANCE) - balanceBefore;
      netProfit += delta;
      if(delta>0) wins++; else if(delta<0) losses++;
      totalTrades++;
   }

   // 4) Manage open trade EVERY tick (trail/BE continue to work)
   if(PositionSelect(_Symbol))
      ManageOpenTrade(EnableTrailingStop, TrailingStartPips, TrailingStepPips,
                      UseBreakEven, BE_TriggerPips, BE_OffsetPips);

   // 5) Panel + finally reset debug (prevents spam)
   panel.Update(netProfit, wins, losses, totalTrades, signalText);
   DebugResetAll();
}
//+------------------------------------------------------------------+
//| Tester event handlers (tester-only; no effect live)              |
//+------------------------------------------------------------------+
void   OnTesterInit()   { TesterInit(); }
double OnTester()       { return UseCustomFitness ? TesterComputeFitness() 
                                                 : TesterStatistics(STAT_PROFIT); }
void   OnTesterPass()   { TesterOnPass(); }
void   OnTesterDeinit() { TesterDeinit(); }