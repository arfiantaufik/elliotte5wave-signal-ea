//+------------------------------------------------------------------+
//|              Elliott Zigzag Trading EA v3.2 (IMPROVED)          |
//|                    Zigzag Pattern with Arrow Signals             |
//|                               https://www.facebook.com/traderknj |
//|                                      Copyright 2016, KNJ company |
//|                                              TraderKNJ@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "TraderKNJ@yahoo.com"
#property link      "https://www.facebook.com/traderknj"
#property version   "3.20"
#property strict
#property description "Elliott Zigzag Trading EA - Improved Swing Detection"

// ===== INPUT PARAMETERS =====
input int Zigzag_Depth = 5;                     // Zigzag Depth untuk deteksi swing
input double Zigzag_Deviation = 2.0;            // Deviation % untuk swing
input int Zigzag_Backstep = 2;                  // Backstep untuk zigzag
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
double swing_highs[20];
double swing_lows[20];
int swing_bars[20];
datetime swing_times[20];
bool last_swing_up = true;
bool signal_generated = false;
string signal_type = "";
int last_processed_bar = -1;

//+------------------------------------------------------------------+
//| Expert initialization function                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("===== Elliott Zigzag Trading EA v3.2 Started =====");
   Print("Symbol: ", Symbol());
   Print("Timeframe: ", Period(), " Minutes");
   Print("Zigzag Depth: ", Zigzag_Depth);
   Print("Zigzag Deviation: ", Zigzag_Deviation, "%");
   
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
   Print("===== Elliott Zigzag Trading EA Stopped =====");
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
//| DETECT ZIGZAG SWINGS - IMPROVED ALGORITHM                       |
//+------------------------------------------------------------------+
void DetectZigzagSwings()
{
   int bars_scan = 200;
   
   // Cari swing highs dan lows
   int high_count = 0;
   int low_count = 0;
   
   double highs[100];
   int high_bars[100];
   datetime high_times[100];
   
   double lows[100];
   int low_bars[100];
   datetime low_times[100];
   
   ArrayInitialize(highs, 0);
   ArrayInitialize(lows, 0);
   ArrayInitialize(high_bars, 0);
   ArrayInitialize(low_bars, 0);
   ArrayInitialize(high_times, 0);
   ArrayInitialize(low_times, 0);
   
   // Scan untuk menemukan local highs
   for(int i = Zigzag_Depth; i < bars_scan - Zigzag_Depth; i++)
   {
      bool is_local_high = true;
      bool is_local_low = true;
      
      // Cek local high
      for(int k = 1; k <= Zigzag_Depth; k++)
      {
         if(High[i] <= High[i-k] || High[i] < High[i+k])
         {
            is_local_high = false;
            break;
         }
      }
      
      // Cek local low
      for(int k = 1; k <= Zigzag_Depth; k++)
      {
         if(Low[i] >= Low[i-k] || Low[i] > Low[i+k])
         {
            is_local_low = false;
            break;
         }
      }
      
      // Simpan local high
      if(is_local_high && high_count < 100)
      {
         highs[high_count] = High[i];
         high_bars[high_count] = i;
         high_times[high_count] = Time[i];
         high_count++;
      }
      
      // Simpan local low
      if(is_local_low && low_count < 100)
      {
         lows[low_count] = Low[i];
         low_bars[low_count] = i;
         low_times[low_count] = Time[i];
         low_count++;
      }
   }
   
   // Filter berdasarkan deviation
   ArrayInitialize(swing_highs, 0);
   ArrayInitialize(swing_lows, 0);
   ArrayInitialize(swing_bars, 0);
   ArrayInitialize(swing_times, 0);
   
   swing_count = 0;
   
   // Gabungkan high dan low dalam urutan waktu untuk membentuk zigzag
   for(int i = 0; i < high_count && swing_count < 20; i++)
   {
      swing_highs[swing_count] = highs[i];
      swing_bars[swing_count] = high_bars[i];
      swing_times[swing_count] = high_times[i];
      swing_count++;
   }
   
   for(int i = 0; i < low_count && swing_count < 20; i++)
   {
      swing_lows[swing_count] = lows[i];
      swing_bars[swing_count] = low_bars[i];
      swing_times[swing_count] = low_times[i];
      swing_count++;
   }
   
   // Sort by time (bubble sort)
   for(int i = 0; i < swing_count; i++)
   {
      for(int j = i + 1; j < swing_count; j++)
      {
         if(swing_times[i] < swing_times[j])
         {
            // Swap
            double temp_high = swing_highs[i];
            double temp_low = swing_lows[i];
            int temp_bar = swing_bars[i];
            datetime temp_time = swing_times[i];
            
            swing_highs[i] = swing_highs[j];
            swing_lows[i] = swing_lows[j];
            swing_bars[i] = swing_bars[j];
            swing_times[i] = swing_times[j];
            
            swing_highs[j] = temp_high;
            swing_lows[j] = temp_low;
            swing_bars[j] = temp_bar;
            swing_times[j] = temp_time;
         }
      }
   }
   
   // Keep only last 10 swings
   if(swing_count > 10)
      swing_count = 10;
   
   Print("Swing Count: ", swing_count);
   
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
         if(ObjectFind(0, line_name) < 0)
         {
            ObjectCreate(0, line_name, OBJ_TREND, 0, time1, price1, time2, price2);
         }
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
            // Swing naik - Arrow UP (kode 241)
            if(ObjectFind(0, arrow_name) < 0)
            {
               ObjectCreate(0, arrow_name, OBJ_ARROW, 0, time2, price2);
            }
            ObjectSetInteger(0, arrow_name, OBJPROP_ARROWCODE, 241);
            ObjectSetInteger(0, arrow_name, OBJPROP_COLOR, clrGreen);
            ObjectSetInteger(0, arrow_name, OBJPROP_WIDTH, 2);
         }
         else if(price2 < price1)
         {
            // Swing turun - Arrow DOWN (kode 242)
            if(ObjectFind(0, arrow_name) < 0)
            {
               ObjectCreate(0, arrow_name, OBJ_ARROW, 0, time2, price2);
            }
            ObjectSetInteger(0, arrow_name, OBJPROP_ARROWCODE, 242);
            ObjectSetInteger(0, arrow_name, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, arrow_name, OBJPROP_WIDTH, 2);
         }
         
         // Tampilkan swing number
         string num_name = "SwingNum_" + (string)i;
         if(ObjectFind(0, num_name) < 0)
         {
            ObjectCreate(0, num_name, OBJ_TEXT, 0, time2, price2);
         }
         ObjectSetString(0, num_name, OBJPROP_TEXT, (string)i);
         ObjectSetInteger(0, num_name, OBJPROP_FONTSIZE, 12);
         ObjectSetString(0, num_name, OBJPROP_FONT, "Arial Bold");
         ObjectSetInteger(0, num_name, OBJPROP_COLOR, clrYellow);
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
   
   Print("Swing 0: ", swing_0, " | Swing 2: ", swing_2, " | Swing 4: ", swing_4);
   
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
   if(ObjectFind(0, signal_name) < 0)
   {
      ObjectCreate(0, signal_name, OBJ_TEXT, 0, Time[0], entry_price - 50*Point);
   }
   ObjectSetString(0, signal_name, OBJPROP_TEXT, "BUY - Swing 5!");
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
   if(ObjectFind(0, signal_name) < 0)
   {
      ObjectCreate(0, signal_name, OBJ_TEXT, 0, Time[0], entry_price + 50*Point);
   }
   ObjectSetString(0, signal_name, OBJPROP_TEXT, "SELL - Swing 5!");
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
