//+------------------------------------------------------------------+
//|                         Elliott Wave Signal EA v2.0              |
//|                               https://www.facebook.com/traderknj |
//|                                      Copyright 2016, KNJ company |
//|                                              TraderKNJ@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "TraderKNJ@yahoo.com"
#property link      "https://www.facebook.com/traderknj"
#property version   "2.00"
#property strict
#property description "Elliott Wave Pattern Signal EA - Auto Detection & Trading"

// ===== INPUT PARAMETERS =====
input int RSI_Period = 14;                      // RSI Period untuk deteksi trend
input double RSI_Overbought = 70;              // RSI Level Overbought
input double RSI_Oversold = 30;                // RSI Level Oversold
input int ATR_Period = 14;                     // ATR Period untuk volatility
input double ATR_Multiplier = 1.5;             // ATR Multiplier untuk SL/TP
input double Lot_Size = 0.1;                   // Ukuran Lot
input bool Use_Money_Management = true;        // Gunakan Money Management
input double Risk_Percent = 2.0;               // Risk % per trade
input int Bars_Look_Back = 50;                 // Jumlah bars untuk analisis
input bool Show_Wave_Label = true;             // Tampilkan label wave
input bool Show_Signal_Alert = true;           // Tampilkan alert signal
input bool Enable_Trading = false;             // Enable Auto Trading (HATI-HATI!)
input bool Use_Sound_Alert = false;            // Gunakan sound alert
input string Sound_File = "alert.wav";         // Nama file sound

// ===== GLOBAL VARIABLES =====
int wave_count = 0;
double wave_points[5];
datetime wave_times[5];
int signal_bar = 0;
bool signal_generated = false;
string signal_type = "";  // "BUY" atau "SELL"

//+------------------------------------------------------------------+
//| Expert initialization function                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("===== Elliott Wave Signal EA Started =====");
   Print("Timeframe: ", Period(), " Minutes");
   Print("Symbol: ", Symbol());
   Print("Risk: ", Risk_Percent, "% per trade");
   
   // Initialize wave points array
   ArrayInitialize(wave_points, 0);
   ArrayInitialize(wave_times, 0);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("===== Elliott Wave Signal EA Stopped =====");
   DeleteAllObjects();
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
   // Deteksi Elliott Wave Pattern
   DetectElliottWave();
   
   // Analisis signal
   AnalyzeSignal();
   
   // Jalankan trading jika enabled
   if(Enable_Trading && signal_generated)
   {
      ExecuteTrade();
   }
}

//+------------------------------------------------------------------+
//| DETECT ELLIOTT WAVE PATTERN                                     |
//+------------------------------------------------------------------+
void DetectElliottWave()
{
   // Cari 5 swing highs dan lows untuk membentuk pattern Elliott Wave
   int swing_count = 0;
   int checked_bars = 0;
   double current_high, current_low;
   bool is_uptrend = true;
   
   // Tentukan trend awal
   if(Close[10] > Close[30]) 
      is_uptrend = true;
   else 
      is_uptrend = false;
   
   // Identifikasi swing points
   for(int i = 1; i < Bars_Look_Back && swing_count < 5; i++)
   {
      // Cari high swing
      if(is_uptrend)
      {
         if(High[i] > High[i-1] && High[i] > High[i+1])
         {
            wave_points[swing_count] = High[i];
            wave_times[swing_count] = Time[i];
            swing_count++;
            is_uptrend = false;
         }
      }
      // Cari low swing
      else
      {
         if(Low[i] < Low[i-1] && Low[i] < Low[i+1])
         {
            wave_points[swing_count] = Low[i];
            wave_times[swing_count] = Time[i];
            swing_count++;
            is_uptrend = true;
         }
      }
   }
   
   wave_count = swing_count;
   
   // Draw wave labels
   if(Show_Wave_Label)
   {
      DrawWaveLabels();
   }
}

//+------------------------------------------------------------------+
//| ANALYZE SIGNAL - DETEKSI PADA WAVE KE-5                        |
//+------------------------------------------------------------------+
void AnalyzeSignal()
{
   // Signal hanya dibuat ketika mencapai wave ke-5
   if(wave_count < 5)
   {
      signal_generated = false;
      return;
   }
   
   // Deteksi tipe signal berdasarkan struktur wave
   double wave_1 = wave_points[0];
   double wave_2 = wave_points[1];
   double wave_3 = wave_points[2];
   double wave_4 = wave_points[3];
   double wave_5 = wave_points[4];
   
   // Validasi Elliott Wave Rules
   bool is_valid_wave = ValidateElliottWave(wave_1, wave_2, wave_3, wave_4, wave_5);
   
   if(!is_valid_wave)
   {
      signal_generated = false;
      return;
   }
   
   // Deteksi trend direction
   if(wave_1 < wave_3 && wave_3 < wave_5)
   {
      // UPTREND - BUY SIGNAL pada completion wave 5
      signal_type = "BUY";
      signal_generated = true;
      signal_bar = 0;
      
      if(Show_Signal_Alert)
      {
         ShowBuySignal(wave_5);
      }
   }
   else if(wave_1 > wave_3 && wave_3 > wave_5)
   {
      // DOWNTREND - SELL SIGNAL pada completion wave 5
      signal_type = "SELL";
      signal_generated = true;
      signal_bar = 0;
      
      if(Show_Signal_Alert)
      {
         ShowSellSignal(wave_5);
      }
   }
   else
   {
      signal_generated = false;
   }
}

//+------------------------------------------------------------------+
//| VALIDATE ELLIOTT WAVE RULES                                     |
//+------------------------------------------------------------------+
bool ValidateElliottWave(double w1, double w2, double w3, double w4, double w5)
{
   // Rule 1: Wave 3 tidak boleh paling pendek
   // Rule 2: Wave 4 tidak boleh masuk territory wave 1
   // Rule 3: Wave 2 tidak boleh melampaui wave 1
   
   bool uptrend = (w1 < w3 && w3 < w5);
   bool downtrend = (w1 > w3 && w3 > w5);
   
   if(uptrend)
   {
      // Validasi uptrend
      if(w2 < w1 && w4 < w3 && w4 > w2)
      {
         return true;
      }
   }
   else if(downtrend)
   {
      // Validasi downtrend
      if(w2 > w1 && w4 > w3 && w4 < w2)
      {
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| DRAW WAVE LABELS                                                |
//+------------------------------------------------------------------+
void DrawWaveLabels()
{
   DeleteWaveLabels();
   
   for(int i = 0; i < wave_count && i < 5; i++)
   {
      string label_name = "Wave_" + IntToString(i);
      string label_text = IntToString(i);
      
      if(ObjectFind(0, label_name) < 0)
      {
         ObjectCreate(0, label_name, OBJ_TEXT, 0, wave_times[i], wave_points[i]);
      }
      
      ObjectSetString(0, label_name, OBJPROP_TEXT, label_text);
      ObjectSetInteger(0, label_name, OBJPROP_FONTSIZE, 16);
      ObjectSetString(0, label_name, OBJPROP_FONT, "Arial Bold");
      
      // Ubah warna berdasarkan wave number
      if(i % 2 == 0)
         ObjectSetInteger(0, label_name, OBJPROP_COLOR, clrBlue);
      else
         ObjectSetInteger(0, label_name, OBJPROP_COLOR, clrRed);
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
   
   // Create buy signal object
   DeleteSignalObjects();
   
   string signal_name = "BUY_SIGNAL_" + TimeToString(TimeCurrent());
   ObjectCreate(0, signal_name, OBJ_TEXT, 0, Time[0], Ask + 100*Point);
   ObjectSetString(0, signal_name, OBJPROP_TEXT, "BUY SIGNAL - Wave 5 Complete!");
   ObjectSetInteger(0, signal_name, OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(0, signal_name, OBJPROP_COLOR, clrGreen);
   ObjectSetString(0, signal_name, OBJPROP_FONT, "Arial Bold");
   
   // Notification
   if(Use_Sound_Alert)
      PlaySound(Sound_File);
      
   Alert("BUY SIGNAL DETECTED! - ", Symbol(), " at ", TimeToString(TimeCurrent()));
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
   
   // Create sell signal object
   DeleteSignalObjects();
   
   string signal_name = "SELL_SIGNAL_" + TimeToString(TimeCurrent());
   ObjectCreate(0, signal_name, OBJ_TEXT, 0, Time[0], Bid - 100*Point);
   ObjectSetString(0, signal_name, OBJPROP_TEXT, "SELL SIGNAL - Wave 5 Complete!");
   ObjectSetInteger(0, signal_name, OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(0, signal_name, OBJPROP_COLOR, clrRed);
   ObjectSetString(0, signal_name, OBJPROP_FONT, "Arial Bold");
   
   // Notification
   if(Use_Sound_Alert)
      PlaySound(Sound_File);
      
   Alert("SELL SIGNAL DETECTED! - ", Symbol(), " at ", TimeToString(TimeCurrent()));
}

//+------------------------------------------------------------------+
//| EXECUTE TRADE                                                   |
//+------------------------------------------------------------------+
void ExecuteTrade()
{
   // Hanya buka 1 trade per signal
   if(CountOpenTrades() > 0)
      return;
   
   double lot = Lot_Size;
   double atr = iATR(Symbol(), Period(), ATR_Period, 0);
   double stop_loss = atr * ATR_Multiplier;
   double take_profit = stop_loss * 2;  // Risk Reward Ratio 1:2
   
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
                             "Elliott Wave BUY", 0, 0, clrGreen);
      
      if(ticket > 0)
      {
         Print("BUY Order Opened: Ticket #", ticket);
      }
      else
      {
         Print("Buy Order Failed! Error: ", GetLastError());
      }
   }
   else if(signal_type == "SELL")
   {
      double sell_entry = Bid;
      double sell_sl = sell_entry + stop_loss;
      double sell_tp = sell_entry - take_profit;
      
      int ticket = OrderSend(Symbol(), OP_SELL, lot, sell_entry, 3, sell_sl, sell_tp, 
                             "Elliott Wave SELL", 0, 0, clrRed);
      
      if(ticket > 0)
      {
         Print("SELL Order Opened: Ticket #", ticket);
      }
      else
      {
         Print("Sell Order Failed! Error: ", GetLastError());
      }
   }
   
   signal_generated = false;
}

//+------------------------------------------------------------------+
//| CALCULATE LOT SIZE BASED ON RISK                               |
//+------------------------------------------------------------------+
double CalculateLotSize(double stop_loss_pips)
{
   double account_balance = AccountBalance();
   double risk_amount = (account_balance * Risk_Percent) / 100;
   double pip_value = (Symbol() == "EURUSD" || Symbol() == "GBPUSD") ? 0.0001 : 0.01;
   double lot = (risk_amount / (stop_loss_pips / pip_value)) / 100000;
   
   // Ensure minimum lot
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
//| DELETE WAVE LABELS                                              |
//+------------------------------------------------------------------+
void DeleteWaveLabels()
{
   for(int i = 0; i < 5; i++)
   {
      string label_name = "Wave_" + IntToString(i);
      
      if(ObjectFind(0, label_name) >= 0)
      {
         ObjectDelete(0, label_name);
      }
   }
}

//+------------------------------------------------------------------+
//| DELETE SIGNAL OBJECTS                                           |
//+------------------------------------------------------------------+
void DeleteSignalObjects()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      string obj_name = ObjectName(i);
      
      if(StringFind(obj_name, "BUY_SIGNAL_") == 0 || StringFind(obj_name, "SELL_SIGNAL_") == 0)
      {
         ObjectDelete(0, obj_name);
      }
   }
}

//+------------------------------------------------------------------+
//| DELETE ALL OBJECTS                                              |
//+------------------------------------------------------------------+
void DeleteAllObjects()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      string obj_name = ObjectName(i);
      
      if(StringFind(obj_name, "Wave_") == 0 || StringFind(obj_name, "BUY_SIGNAL_") == 0 || 
         StringFind(obj_name, "SELL_SIGNAL_") == 0)
      {
         ObjectDelete(0, obj_name);
      }
   }
}

//+------------------------------------------------------------------+
