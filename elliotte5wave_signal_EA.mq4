//+------------------------------------------------------------------+
//|                  Elliott Wave Zigzag Signal EA v3.0              |
//|                    Zigzag Pattern with Arrow Signals             |
//|                               https://www.facebook.com/traderknj |
//|                                      Copyright 2016, KNJ company |
//|                                              TraderKNJ@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "TraderKNJ@yahoo.com"
#property link      "https://www.facebook.com/traderknj"
#property version   "3.00"
#property strict
#property description "Elliott Wave Zigzag EA - Arrow Signals & Swing Detection"

// ===== INPUT PARAMETERS =====
input int Zigzag_Depth = 12;                    // Zigzag Depth untuk deteksi swing
input double Zigzag_Deviation = 5.0;            // Deviation % untuk swing
input int Zigzag_Backstep = 3;                  // Backstep untuk zigzag
input double Lot_Size = 0.1;                    // Ukuran Lot
input bool Use_Money_Management = true;        // Gunakan Money Management
input double Risk_Percent = 2.0;               // Risk % per trade
input bool Show_Zigzag_Line = true;            // Tampilkan garis zigzag
input bool Show_Arrows = true;                 // Tampilkan arrow signals
input bool Show_Signal_Alert = true;           // Tampilkan alert signal
input bool Enable_Trading = false;             // Enable Auto Trading
input bool Use_Sound_Alert = false;            // Gunakan sound alert
input string Sound_File = "alert.wav";         // Nama file sound
input int ATR_Period = 14;                     // ATR Period untuk SL/TP
input double ATR_Multiplier = 1.5;             // ATR Multiplier

// ===== GLOBAL VARIABLES =====
int swing_count = 0;
double swing_highs[10];
double swing_lows[10];
int swing_bars[10];
datetime swing_times[10];
bool last_swing_up = true;  // true = naik, false = turun
bool signal_generated = false;
string signal_type = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("===== Elliott Wave Zigzag Signal EA v3.0 Started =====");
   Print("Symbol: ", Symbol());
   Print("Timeframe: ", Period(), " Minutes");
   Print("Zigzag Depth: ", Zigzag_Depth);
   
   ArrayInitialize(swing_highs, 0);
   ArrayInitialize(swing_lows, 0);
   ArrayInitialize(swing_bars, 0);
   ArrayInitialize(swing_times, 0);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("===== Elliott Wave Zigzag Signal EA Stopped =====");
   DeleteAllZigzagObjects();
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
   // Deteksi Zigzag Swing Pattern
   DetectZigzagSwings();
   
   // Analisis signal pada swing ke-5
   AnalyzeSwingSignal();
   
   // Jalankan trading jika enabled
   if(Enable_Trading && signal_generated)
   {
      ExecuteTrade();
   }
}

//+------------------------------------------------------------------+
//| DETECT ZIGZAG SWINGS                                            |
//+------------------------------------------------------------------+
void DetectZigzagSwings()
{
   // Clear previous data
   swing_count = 0;
   ArrayInitialize(swing_highs, 0);
   ArrayInitialize(swing_lows, 0);
   ArrayInitialize(swing_bars, 0);
   ArrayInitialize(swing_times, 0);
   
   int bars_check = 500;  // Jumlah bars untuk di-scan
   int last_high_bar = -1;
   int last_low_bar = -1;
   double last_high = 0;
   double last_low = DBL_MAX;
   bool looking_for_high = true;
   
   // Determine initial direction
   if(Close[50] > Close[100])
      looking_for_high = false;  // Cari low dulu
   else
      looking_for_high = true;   // Cari high dulu
   
   // Scan bars untuk menemukan swings
   for(int i = Zigzag_Depth; i < bars_check; i++)
   {
      // Cari swing LOW
      if(!looking_for_high)
      {
         // Cari low dengan left dan right bars
         if(Low[i] < Low[i-Zigzag_Backstep] && Low[i] < Low[i+Zigzag_Backstep])
         {
            // Validasi deviasi
            if(last_high == 0 || (last_high - Low[i]) / last_high * 100 >= Zigzag_Deviation)
            {
               last_low = Low[i];
               last_low_bar = i;
               looking_for_high = true;  // Next: cari high
               
               // Simpan swing point
               if(swing_count < 10)
               {
                  swing_lows[swing_count] = Low[i];
                  swing_bars[swing_count] = i;
                  swing_times[swing_count] = Time[i];
                  swing_count++;
                  last_swing_up = false;
               }
               
               i += Zigzag_Backstep;
            }
         }
      }
      // Cari swing HIGH
      else
      {
         // Cari high dengan left dan right bars
         if(High[i] > High[i-Zigzag_Backstep] && High[i] > High[i+Zigzag_Backstep])
         {
            // Validasi deviasi
            if(last_low == DBL_MAX || (High[i] - last_low) / last_low * 100 >= Zigzag_Deviation)
            {
               last_high = High[i];
               last_high_bar = i;
               looking_for_high = false;  // Next: cari low
               
               // Simpan swing point
               if(swing_count < 10)
               {
                  swing_highs[swing_count] = High[i];
                  swing_bars[swing_count] = i;
                  swing_times[swing_count] = Time[i];
                  swing_count++;
                  last_swing_up = true;
               }
               
               i += Zigzag_Backstep;
            }
         }
      }
   }
   
   // Draw zigzag lines dan arrows
   if(Show_Zigzag_Line || Show_Arrows)
   {
      DrawZigzagPattern();
   }
}

//+------------------------------------------------------------------+
//| DRAW ZIGZAG PATTERN & ARROWS                                    |
//+------------------------------------------------------------------+
void DrawZigzagPattern()
{
   DeleteAllZigzagObjects();
   
   // Draw garis dan arrows
   for(int i = 0; i < swing_count - 1; i++)
   {
      datetime time1 = swing_times[i];
      datetime time2 = swing_times[i + 1];
      double price1 = (swing_highs[i] != 0) ? swing_highs[i] : swing_lows[i];
      double price2 = (swing_highs[i + 1] != 0) ? swing_highs[i + 1] : swing_lows[i + 1];
      
      // Draw line
      if(Show_Zigzag_Line)
      {
         string line_name = "ZigzagLine_" + (string)i;
         ObjectCreate(0, line_name, OBJ_TREND, 0, time1, price1, time2, price2);
         ObjectSetInteger(0, line_name, OBJPROP_COLOR, clrBlue);
         ObjectSetInteger(0, line_name, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, line_name, OBJPROP_RAY, false);
      }
      
      // Draw arrow
      if(Show_Arrows)
      {
         string arrow_name = "Arrow_" + (string)i;
         
         if(price2 > price1)
         {
            // Swing naik - Arrow UP
            ObjectCreate(0, arrow_name, OBJ_ARROW, 0, time2, price2);
            ObjectSetInteger(0, arrow_name, OBJPROP_ARROWCODE, ARROW_UP);
            ObjectSetInteger(0, arrow_name, OBJPROP_COLOR, clrGreen);
            ObjectSetInteger(0, arrow_name, OBJPROP_WIDTH, 2);
         }
         else
         {
            // Swing turun - Arrow DOWN
            ObjectCreate(0, arrow_name, OBJ_ARROW, 0, time2, price2);
            ObjectSetInteger(0, arrow_name, OBJPROP_ARROWCODE, ARROW_DOWN);
            ObjectSetInteger(0, arrow_name, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, arrow_name, OBJPROP_WIDTH, 2);
         }
         
         // Tampilkan swing number
         string num_name = "SwingNum_" + (string)i;
         ObjectCreate(0, num_name, OBJ_TEXT, 0, time2, price2);
         ObjectSetString(0, num_name, OBJPROP_TEXT, (string)i);
         ObjectSetInteger(0, num_name, OBJPROP_FONTSIZE, 10);
         ObjectSetString(0, num_name, OBJPROP_FONT, "Arial");
         ObjectSetInteger(0, num_name, OBJPROP_COLOR, clrBlack);
      }
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| ANALYZE SWING SIGNAL - SWING KE-5 SELESAI                      |
//+------------------------------------------------------------------+
void AnalyzeSwingSignal()
{
   // Signal hanya saat swing ke-5 terdeteksi
   if(swing_count < 5)
   {
      signal_generated = false;
      return;
   }
   
   // Ambil data swing 0 s/d 4 (5 swings)
   double swing_0 = (swing_highs[0] != 0) ? swing_highs[0] : swing_lows[0];
   double swing_1 = (swing_highs[1] != 0) ? swing_highs[1] : swing_lows[1];
   double swing_2 = (swing_highs[2] != 0) ? swing_highs[2] : swing_lows[2];
   double swing_3 = (swing_highs[3] != 0) ? swing_highs[3] : swing_lows[3];
   double swing_4 = (swing_highs[4] != 0) ? swing_highs[4] : swing_lows[4];
   
   // Validasi pola Zigzag
   bool is_uptrend = (swing_0 < swing_2 && swing_2 < swing_4);
   bool is_downtrend = (swing_0 > swing_2 && swing_2 > swing_4);
   
   if(is_uptrend)
   {
      // UPTREND - BUY SIGNAL
      signal_type = "BUY";
      signal_generated = true;
      
      if(Show_Signal_Alert)
      {
         ShowBuySignal(swing_4);
      }
   }
   else if(is_downtrend)
   {
      // DOWNTREND - SELL SIGNAL
      signal_type = "SELL";
      signal_generated = true;
      
      if(Show_Signal_Alert)
      {
         ShowSellSignal(swing_4);
      }
   }
   else
   {
      signal_generated = false;
   }
}

//+------------------------------------------------------------------+
//| SHOW BUY SIGNAL                                                 |
//+------------------------------------------------------------------+
void ShowBuySignal(double entry_price)
{
   Print("========== BUY SIGNAL ==========");
   Print("Time: ", TimeToString(TimeCurrent()));
   Print("Symbol: ", Symbol());
   Print("Entry Price: ", entry_price);
   Print("Swing Count: ", swing_count);
   
   // Create buy signal marker
   string signal_name = "BUY_SIGNAL_" + (string)TimeCurrent();
   ObjectCreate(0, signal_name, OBJ_TEXT, 0, Time[0], entry_price - 50*Point);
   ObjectSetString(0, signal_name, OBJPROP_TEXT, "BUY - Swing 5 Complete!");
   ObjectSetInteger(0, signal_name, OBJPROP_FONTSIZE, 14);
   ObjectSetInteger(0, signal_name, OBJPROP_COLOR, clrGreen);
   ObjectSetString(0, signal_name, OBJPROP_FONT, "Arial Bold");
   
   if(Use_Sound_Alert)
      PlaySound(Sound_File);
      
   Alert("BUY SIGNAL! Swing 5 Complete - ", Symbol());
}

//+------------------------------------------------------------------+
//| SHOW SELL SIGNAL                                                |
//+------------------------------------------------------------------+
void ShowSellSignal(double entry_price)
{
   Print("========== SELL SIGNAL ==========");
   Print("Time: ", TimeToString(TimeCurrent()));
   Print("Symbol: ", Symbol());
   Print("Entry Price: ", entry_price);
   Print("Swing Count: ", swing_count);
   
   // Create sell signal marker
   string signal_name = "SELL_SIGNAL_" + (string)TimeCurrent();
   ObjectCreate(0, signal_name, OBJ_TEXT, 0, Time[0], entry_price + 50*Point);
   ObjectSetString(0, signal_name, OBJPROP_TEXT, "SELL - Swing 5 Complete!");
   ObjectSetInteger(0, signal_name, OBJPROP_FONTSIZE, 14);
   ObjectSetInteger(0, signal_name, OBJPROP_COLOR, clrRed);
   ObjectSetString(0, signal_name, OBJPROP_FONT, "Arial Bold");
   
   if(Use_Sound_Alert)
      PlaySound(Sound_File);
      
   Alert("SELL SIGNAL! Swing 5 Complete - ", Symbol());
}

//+------------------------------------------------------------------+
//| EXECUTE TRADE                                                   |
//+------------------------------------------------------------------+
void ExecuteTrade()
{
   // Hanya 1 trade per signal
   if(CountOpenTrades() > 0)
      return;
   
   double lot = Lot_Size;
   double atr = iATR(Symbol(), Period(), ATR_Period, 0);
   double stop_loss = atr * ATR_Multiplier;
   double take_profit = stop_loss * 2;
   
   if(Use_Money_Management)
   {
      lot = CalculateLotSize(stop_loss);
   }
   
   if(signal_type == "BUY")
   {
      double buy_entry = Ask;
      double buy_sl = buy_entry - stop_loss;
      double buy_tp = buy_entry + take_profit;
      
      int ticket = OrderSend(Symbol(), OP_BUY, lot, buy_entry, 3, buy_sl, buy_tp,
                             "Zigzag BUY", 0, 0, clrGreen);
      
      if(ticket > 0)
         Print("BUY Order: Ticket #", ticket);
      else
         Print("Buy Order Failed! Error: ", GetLastError());
   }
   else if(signal_type == "SELL")
   {
      double sell_entry = Bid;
      double sell_sl = sell_entry + stop_loss;
      double sell_tp = sell_entry - take_profit;
      
      int ticket = OrderSend(Symbol(), OP_SELL, lot, sell_entry, 3, sell_sl, sell_tp,
                             "Zigzag SELL", 0, 0, clrRed);
      
      if(ticket > 0)
         Print("SELL Order: Ticket #", ticket);
      else
         Print("Sell Order Failed! Error: ", GetLastError());
   }
   
   signal_generated = false;
}

//+------------------------------------------------------------------+
//| CALCULATE LOT SIZE                                              |
//+------------------------------------------------------------------+
double CalculateLotSize(double stop_loss_pips)
{
   double account_balance = AccountBalance();
   double risk_amount = (account_balance * Risk_Percent) / 100;
   double pip_value = (Symbol() == "EURUSD" || Symbol() == "GBPUSD") ? 0.0001 : 0.01;
   double lot = (risk_amount / (stop_loss_pips / pip_value)) / 100000;
   
   if(lot < 0.01)
      lot = 0.01;
   
   return(lot);
}

//+------------------------------------------------------------------+
//| COUNT OPEN TRADES                                               |
//+------------------------------------------------------------------+
int CountOpenTrades()
{
   int count = 0;
   
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS))
      {
         if(OrderSymbol() == Symbol() && OrderType() < 2)
         {
            count++;
         }
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| DELETE ALL ZIGZAG OBJECTS                                       |
//+------------------------------------------------------------------+
void DeleteAllZigzagObjects()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      string obj_name = ObjectName(i);
      
      if(StringFind(obj_name, "ZigzagLine_") == 0 || 
         StringFind(obj_name, "Arrow_") == 0 ||
         StringFind(obj_name, "SwingNum_") == 0 ||
         StringFind(obj_name, "BUY_SIGNAL_") == 0 ||
         StringFind(obj_name, "SELL_SIGNAL_") == 0)
      {
         ObjectDelete(0, obj_name);
      }
   }
}

//+------------------------------------------------------------------+
