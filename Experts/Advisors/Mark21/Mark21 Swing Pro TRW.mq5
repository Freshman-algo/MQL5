//+------------------------------------------------------------------+
//|                                                   Mark21_Swing_Pro_TRW.mq5 |
//|                     Author: Freshman | Version: 1.9 | June 2025             |
//|  Description: TRW strategy swing EA with MA zones, SQZPRO + Info Panel     |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
#include <ChartObjects/ChartObjectsTxtControls.mqh>
#include <ChartObjects/ChartObjectsShapes.mqh>

input bool     EnableTrading      = true;
input bool     ShowInfoPanel      = true;
input int      MagicNumber        = 2101;
input double   LotSize            = 0.01;
input ENUM_TIMEFRAMES ZoneTF_Daily = PERIOD_D1;
input ENUM_TIMEFRAMES ZoneTF_Hourly = PERIOD_H1;
input ENUM_TIMEFRAMES ZoneTF_Weekly = PERIOD_W1;
input ENUM_TIMEFRAMES EntryTF      = PERIOD_M15;

// MA Periods
input int MA_9_Period  = 9;
input int MA_21_Period = 21;
input int MA_50_Period = 50;

// SQZPRO Inputs
input int    BB_Period = 20;
input double BB_Dev    = 2.0;
input int    KC_Period = 20;
input double KC_Mult   = 1.5;

// Handles
int maHandle9, maHandle21, maHandle50;
int bbHandle;        // Bollinger Bands handle
int kcMaHandle;      // EMA handle for Keltner centerline
int kcAtrHandle;     // ATR handle for Keltner bands

// Arrays
double ma9[], ma21[], ma50[];
double bbUpper[], bbLower[];
double kcUpper[], kcLower[];
MqlRates currentRates[];

CTrade trade;

//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize MA handles
   maHandle9  = iMA(_Symbol, _Period, MA_9_Period, 0, MODE_SMA, PRICE_CLOSE);
   maHandle21 = iMA(_Symbol, _Period, MA_21_Period, 0, MODE_SMA, PRICE_CLOSE);
   maHandle50 = iMA(_Symbol, _Period, MA_50_Period, 0, MODE_SMA, PRICE_CLOSE);
   
   // Initialize Bollinger Bands
   bbHandle = iBands(_Symbol, _Period, BB_Period, 0, BB_Dev, PRICE_CLOSE);
   
   // Initialize Keltner Channel components
   kcMaHandle = iMA(_Symbol, _Period, KC_Period, 0, MODE_EMA, PRICE_TYPICAL);
   kcAtrHandle = iATR(_Symbol, _Period, KC_Period);

   // Verify handles
   if(maHandle9 == INVALID_HANDLE || maHandle21 == INVALID_HANDLE || maHandle50 == INVALID_HANDLE ||
      bbHandle == INVALID_HANDLE || kcMaHandle == INVALID_HANDLE || kcAtrHandle == INVALID_HANDLE)
   {
      Print("Failed to load indicators: ", GetLastError());
      return INIT_FAILED;
   }
   
   // Configure trade object
   trade.SetExpertMagicNumber(MagicNumber);
   ArraySetAsSeries(ma9, true);
   ArraySetAsSeries(ma21, true);
   ArraySetAsSeries(ma50, true);
   ArraySetAsSeries(bbUpper, true);
   ArraySetAsSeries(bbLower, true);
   ArraySetAsSeries(kcUpper, true);
   ArraySetAsSeries(kcLower, true);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(!EnableTrading) return;

   // Get current market data
   if(CopyRates(_Symbol, _Period, 0, 1, currentRates) < 1) return;
   datetime currentTime = currentRates[0].time;
   double currentHigh = currentRates[0].high;

   // Copy indicator data
   if(CopyBuffer(maHandle9, 0, 0, 3, ma9) < 3) return;
   if(CopyBuffer(maHandle21, 0, 0, 3, ma21) < 3) return;
   if(CopyBuffer(maHandle50, 0, 0, 3, ma50) < 3) return;
   
   // Copy BB buffers
   if(CopyBuffer(bbHandle, 1, 0, 3, bbUpper) < 3) return;
   if(CopyBuffer(bbHandle, 2, 0, 3, bbLower) < 3) return;
   
   // Calculate Keltner Channel manually
   double kcMa[3], kcAtr[3];
   if(CopyBuffer(kcMaHandle, 0, 0, 3, kcMa) < 3) return;
   if(CopyBuffer(kcAtrHandle, 0, 0, 3, kcAtr) < 3) return;
   
   for(int i = 0; i < 3; i++) {
      kcUpper[i] = kcMa[i] + (KC_Mult * kcAtr[i]);
      kcLower[i] = kcMa[i] - (KC_Mult * kcAtr[i]);
   }

   // Market State
   bool bullish = (ma9[0] > ma21[0]) && (ma21[0] > ma50[0]);
   bool bearish = (ma9[0] < ma21[0]) && (ma21[0] < ma50[0]);
   bool choppy  = !bullish && !bearish;

   // SQZPRO Dot
   string sqzText = "";
   color sqzColor = clrLime;
   if(bbUpper[0] < kcUpper[0] && bbLower[0] > kcLower[0]) {
      sqzText = "Yellow"; 
      sqzColor = clrYellow;
   }
   else if(bbUpper[0] < kcUpper[0]) {
      sqzText = "Red"; 
      sqzColor = clrRed;
   }
   else if(bbLower[0] > kcLower[0]) {
      sqzText = "Black"; 
      sqzColor = clrBlack;
   }
   else {
      sqzText = "Green"; 
      sqzColor = clrLime;
   }

   // Visual SQZ Dot
   string dotName = "sqz_dot_" + TimeToString(currentTime, TIME_MINUTES);
   double dotPrice = currentHigh + 5 * _Point;
   
   // Create circle using arrow object
   ObjectDelete(0, dotName); // Remove previous dot
   if(ObjectCreate(0, dotName, OBJ_ARROW, 0, currentTime, dotPrice)) {
      ObjectSetInteger(0, dotName, OBJPROP_ARROWCODE, 108); // Circle symbol
      ObjectSetInteger(0, dotName, OBJPROP_COLOR, sqzColor);
      ObjectSetInteger(0, dotName, OBJPROP_WIDTH, 3);
      ObjectSetInteger(0, dotName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   }

   // Position check
   bool hasPosition = (PositionsTotal() > 0);

   // Entry logic
   if(bullish && !hasPosition) {
      trade.Buy(LotSize, _Symbol);
   }
   else if(bearish && !hasPosition) {
      trade.Sell(LotSize, _Symbol);
   }

   // Draw Boxes
   DrawZoneBox(ZoneTF_Weekly, "WZ_");
   DrawZoneBox(ZoneTF_Daily,  "DZ_");
   DrawZoneBox(ZoneTF_Hourly, "HZ_");

   // Info Panel
   if(ShowInfoPanel)
      DrawInfoPanel(bullish, bearish, choppy, sqzText);
}

//+------------------------------------------------------------------+
void DrawZoneBox(ENUM_TIMEFRAMES tf, string prefix)
{
   MqlRates rates[];
   if(CopyRates(_Symbol, tf, 0, 2, rates) < 2) return;

   datetime t1 = rates[1].time;
   datetime t2 = rates[0].time;
   double high = MathMax(rates[0].high, rates[1].high);
   double low  = MathMin(rates[0].low, rates[1].low);

   string name = prefix + TimeToString(t2, TIME_DATE|TIME_MINUTES);
   ObjectDelete(0, name); // Remove previous box
   
   if(ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, high, t2, low)) {
      // Use ARGB color with transparency
      uint transparentGray = ColorToARGB(clrGray, 75);
      
      ObjectSetInteger(0, name, OBJPROP_COLOR, transparentGray);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, transparentGray);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
   }
}

//+------------------------------------------------------------------+
void DrawInfoPanel(bool bull, bool bear, bool chop, string squeeze)
{
   string label = "InfoPanel";
   string text;
   color stateColor;

   if(bull) {
      text = "State: Bullish";
      stateColor = clrLimeGreen;
   }
   else if(bear) {
      text = "State: Bearish";
      stateColor = clrRed;
   }
   else {
      text = "State: Choppy";
      stateColor = clrOrange;
   }

   text += "\nSQZPRO: " + squeeze;
   text += StringFormat("\nMA: %.2f > %.2f > %.2f", ma9[0], ma21[0], ma50[0]);
   text += "\n" + TimeToString(TimeCurrent(), TIME_MINUTES);

   if(ObjectFind(0, label) < 0) {
      ObjectCreate(0, label, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, label, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, label, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, label, OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, label, OBJPROP_FONTSIZE, 10);
   }
   
   ObjectSetInteger(0, label, OBJPROP_COLOR, stateColor);
   ObjectSetString(0, label, OBJPROP_TEXT, text);
}
//+------------------------------------------------------------------+