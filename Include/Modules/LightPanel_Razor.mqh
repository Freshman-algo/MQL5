// File: Modules/LightPanel_Razor.mqh
#ifndef __LIGHTPANEL_RAZOR_MQH__
#define __LIGHTPANEL_RAZOR_MQH__

#include <ChartObjects/ChartObjectsTxtControls.mqh>

class RazorPanel
{
private:
   string labelName;
   int    xPad, yPad;

public:
   RazorPanel(string name = "RazorPanel", int x = 10, int y = 20)
   {
      labelName = name;
      xPad      = x;
      yPad      = y;
   }

   void Update(double pnlValue, int winCount, int lossCount, int tradeCount, string signalText)
   {
      string status = EA_ON ? "🟢 ON" : "🔴 OFF";
      string sessionText = IsTradingTime(StartHour, EndHour)
                           ? "📅 Session: 🟢 Live"
                           : "📅 Session: 🔒 Closed";
      int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

      string panelText = StringFormat(
         "💻 Mark21 Razor Panel\n"
         "🔌 EA: %s\n"
         "%s\n"
         "📈 Spread: %d\n"
         "📊 Profit: %.2f\n"
         "✅ Wins: %d   ❌ Losses: %d\n"
         "📦 Trades: %d\n"
         "📍 Signal: %s",
         status, sessionText, spread, pnlValue, winCount, lossCount, tradeCount, signalText
      );

      Draw(panelText);
   }

private:
   void Draw(string text)
   {
      if(ObjectFind(0, labelName) >= 0)
         ObjectDelete(0, labelName);

      ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, xPad);
      ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, yPad);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 12);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, false);
      ObjectSetString(0, labelName, OBJPROP_TEXT, text);
   }
};

#endif // __LIGHTPANEL_RAZOR_MQH__
