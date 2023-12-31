//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "Big Volume Candles"
#property strict
#property indicator_chart_window
#property indicator_buffers 5
//#property indicator_plots   0 // disable
#property indicator_plots   1 // enable
#property indicator_label1  "Big Volume Candles"
#property indicator_type1   DRAW_COLOR_CANDLES

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input ENUM_TIMEFRAMES            inpTimeframe            = PERIOD_CURRENT;
input int                        inpPeriodos             = 60;
input bool                       shortMode               = false;
input int                        input_start             = 0;
input int                        input_end               = 0;
input double                     VolUltra                = 4;
input double                     VolVeryHigh             = 3;
input double                     VolHigh                 = 0;
input double                     VolMedium               = 0;
input double                     VolLow                  = 0;
input double                     inp_minCandleSize       = 0.0;
input double                     inp_fator_tamanho       = 0;
input int                        WaitMilliseconds        = 2000;   // Timer (milliseconds) for recalculation
input bool                       enable_segundo_ativo    = true;
input bool                       enable_tick             = false;
input bool                       enable_real             = true;

input ENUM_LINE_STYLE            styleReal               = STYLE_SOLID;
input ENUM_LINE_STYLE            styleTick               = STYLE_DASH;
input int                        largura                 = 2;

input color                      colorNoColor            = C'65,65,65';
input color                      colorUltraUp              = clrLime;
input color                      colorVeryHighUp           = clrRoyalBlue;
input color                      colorHighUp               = clrCyan;
input color                      colorMedium             = clrNONE;
input color                      colorLow                = clrNONE;
input color                      colorUltraDn              = clrFuchsia;
input color                      colorVeryHighDn           = clrRed;
input color                      colorHighDn               = clrOrange;


input bool                       debug                   = false;
input datetime                   defaultInitialDate = "2023.01.04 10:00:00";                 // Data inicial padrão
input bool                       drawSR = false;
input bool                       only_plot_starts = true;
input bool                       use_high_low = true;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//--- indicator buffers
double ExtOpenBuffer[];
double ExtHighBuffer[];
double ExtLowBuffer[];
double ExtCloseBuffer[];
datetime ExtTimeBuffer[];
double ExtColorsBuffer[];
long volBuffer[];

double _VolUltra = 99999;
double _VolVeryHigh = 99999;
double _VolHigh = 99999;
double _VolMedium = 99999;
double _VolLow = 99999;

int totalRates;
float minCandleSize = inp_minCandleSize / 100;
double fator_tamanho = inp_fator_tamanho;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);

   SetIndexBuffer(0, ExtOpenBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, ExtLowBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, ExtCloseBuffer, INDICATOR_DATA);
//SetIndexBuffer(4, ExtCloseBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, ExtColorsBuffer, INDICATOR_COLOR_INDEX);

//--- don't show indicator data in DataWindow
   PlotIndexSetInteger(0, PLOT_SHOW_DATA, true);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   PlotIndexSetInteger(0, PLOT_COLOR_INDEXES, 9);

//Specify colors for each index
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, colorNoColor);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 1, colorUltraUp);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 2, colorVeryHighUp);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 3, colorHighUp);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 4, colorMedium);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 5, colorLow);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 6, colorUltraDn);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 7, colorVeryHighDn);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 8, colorHighDn);

   if (VolUltra > 0) _VolUltra = VolUltra;
   if (VolVeryHigh > 0) _VolVeryHigh = VolVeryHigh;
   if (VolHigh > 0) _VolHigh = VolHigh;
   if (VolMedium > 0) _VolMedium = VolMedium;
   if (VolLow > 0) _VolLow = VolLow;

   if (fator_tamanho <= 0)
      fator_tamanho = 1;

   _lastOK = false;
   EventSetMillisecondTimer(WaitMilliseconds);

//Update();
//ChartRedraw();

   return (INIT_SUCCEEDED);

}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   return (1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
//EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      _lastOK = Update();
      if (debug) Print("Big Volume Candles " + " " + _Symbol + ":" + GetTimeFrame(Period()) + " ok");

      //EventSetTimer(WaitMilliseconds);

      ChartRedraw();

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawSR(string p_ativo, string p_volume) {

   long periodos = inpPeriodos;
   ENUM_LINE_STYLE estilo;

//CalculateRegression(barFrom, barTo, RegressionSource);

//if (enable_segundo_ativo) {
//string segundo_ativo = _Symbol + "N";
   totalRates = SeriesInfoInteger(p_ativo, inpTimeframe, SERIES_BARS_COUNT);
   int start = iBarShift(p_ativo, inpTimeframe, defaultInitialDate);
//totalRates = start;
   ArrayResize(ExtCloseBuffer, totalRates);
   ArrayResize(ExtHighBuffer, totalRates);
   ArrayResize(ExtLowBuffer, totalRates);
   ArrayResize(ExtOpenBuffer, totalRates);
   ArrayResize(ExtTimeBuffer, totalRates);
   ArrayResize(volBuffer, totalRates);

   ArrayInitialize(ExtCloseBuffer, 0);
   ArrayInitialize(ExtHighBuffer, 0);
   ArrayInitialize(ExtLowBuffer, 0);
   ArrayInitialize(ExtOpenBuffer, 0);
   ArrayInitialize(ExtTimeBuffer, 0);
   ArrayInitialize(volBuffer, 0);

   CopyOpen(p_ativo, inpTimeframe, 0, totalRates, ExtOpenBuffer);
   CopyHigh(p_ativo, inpTimeframe, 0, totalRates, ExtHighBuffer);
   CopyLow(p_ativo, inpTimeframe, 0, totalRates, ExtLowBuffer);
   CopyClose(p_ativo, inpTimeframe, 0, totalRates, ExtCloseBuffer);
   CopyTime(p_ativo, inpTimeframe, 0, totalRates, ExtTimeBuffer);

   if (p_volume == "tick") {
      CopyTickVolume(p_ativo, inpTimeframe, 0, totalRates, volBuffer);
      estilo = styleTick;
   } else {
      CopyRealVolume(p_ativo, inpTimeframe, 0, totalRates, volBuffer);
      estilo = styleReal;
   }

//if (ExtCloseBuffer[totalRates - 1] <= 0)
//   return;
   ArrayInitialize(ExtColorsBuffer, 0);

   int limit = 5000;

   ObjectsDeleteAll(0, "vol_top_");
   ObjectsDeleteAll(0, "vol_bottom_");

   for (int i = totalRates - 1; i > periodos; i--) {
      double volume_total = 0, media = 0;
      double candle_size = 0;
      double tamanho_total = 0, tamanho_medio = 0;

      for (int k = i; k > i - periodos; k--) {
         volume_total = volume_total + volBuffer[k];
         candle_size = MathAbs(ExtHighBuffer[k] - ExtLowBuffer[k]) / ExtCloseBuffer[k];
         tamanho_total = tamanho_total + candle_size;
         int a = 0;
      }
      media = volume_total / periodos;
      tamanho_medio = tamanho_total / periodos;
      candle_size = MathAbs(ExtHighBuffer[i] - ExtLowBuffer[i]) / ExtCloseBuffer[i];

      datetime end_time, start_time;
      if (shortMode) {
         start_time = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * input_start;
         end_time = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * input_end;
      } else {
         start_time = iTime(p_ativo, inpTimeframe, i);
         end_time = iTime(p_ativo, PERIOD_CURRENT, 0);
      }

      if (tamanho_medio > 0 && candle_size >= tamanho_medio * fator_tamanho && candle_size >= minCandleSize) {
         ExtColorsBuffer[i] = 0;
         double volume = volBuffer[i];
         if (volume >= media * _VolUltra) {
            ExtColorsBuffer[i] = ExtCloseBuffer[i] >= ExtOpenBuffer[i] ? 1 : 6;
            color cor = ExtCloseBuffer[i] >= ExtOpenBuffer[i] ? 1 : 6;
            if (volume / media >= _VolUltra)
               cor = ExtCloseBuffer[i] >= ExtOpenBuffer[i] ? 1 : 6;


            if (drawSR && i > totalRates - limit) {
               if (!only_plot_starts) {
                  string name = "vol_bull_" + p_ativo + "_" + p_volume + "_" + i;
                  if (ExtCloseBuffer[i] >= ExtOpenBuffer[i])
                     ObjectCreate(0, name, OBJ_TREND, 0, start_time, ExtCloseBuffer[i], end_time, ExtCloseBuffer[i]);
                  else
                     ObjectCreate(0, name, OBJ_TREND, 0, start_time, ExtOpenBuffer[i], end_time, ExtOpenBuffer[i]);

                  ObjectSetInteger(0, name, OBJPROP_COLOR, colorUltraUp);

                  ObjectSetInteger(0, name, OBJPROP_STYLE, estilo);
                  ObjectSetInteger(0, name, OBJPROP_WIDTH, largura);
                  ObjectSetString(0, name, OBJPROP_TOOLTIP,
                                  "Data: " + ExtTimeBuffer[i] +
                                  "\nTamanho: " + DoubleToString(candle_size * 100, 2) + "% (" + DoubleToString(candle_size / tamanho_medio, 2) + "x " +
                                  "média: " + DoubleToString(tamanho_medio * 100, 2) + "%)" +
                                  "\nVolume: " + DoubleToStrCommaSep(volume, 2) + " (" + DoubleToString(volume / media, 2) + "x " +
                                  "média: " + DoubleToStrCommaSep(media, 2) + ")");

                  name = "vol_bear_" + p_ativo + "_" + p_volume + "_" + i;
                  if (ExtCloseBuffer[i] >= ExtOpenBuffer[i])
                     ObjectCreate(0, name, OBJ_TREND, 0, start_time, ExtOpenBuffer[i], end_time, ExtOpenBuffer[i]);
                  else
                     ObjectCreate(0, name, OBJ_TREND, 0, start_time, ExtCloseBuffer[i], end_time, ExtCloseBuffer[i]);

                  ObjectSetInteger(0, name, OBJPROP_COLOR, colorUltraDn);

                  ObjectSetInteger(0, name, OBJPROP_STYLE, estilo);
                  ObjectSetInteger(0, name, OBJPROP_WIDTH, largura);
                  ObjectSetString(0, name, OBJPROP_TOOLTIP,
                                  "Data: " + ExtTimeBuffer[i] +
                                  "\nTamanho: " + DoubleToString(candle_size * 100, 2) + "% (" + DoubleToString(candle_size / tamanho_medio, 2) + "x " +
                                  "média: " + DoubleToString(tamanho_medio * 100, 2) + "%)" +
                                  "\nVolume: " + DoubleToStrCommaSep(volume, 2) + " (" + DoubleToString(volume / media, 2) + "x " +
                                  "média: " + DoubleToStrCommaSep(media, 2) + ")");
               } else {
                  string name = "vol_bull_" + p_ativo + "_" + p_volume + "_" + i;
                  if (ExtCloseBuffer[i] >= ExtOpenBuffer[i]) {
                     if (use_high_low) {
                        ObjectCreate(0, name, OBJ_TREND, 0, start_time, ExtHighBuffer[i], end_time, ExtHighBuffer[i]);
                     } else {
                        ObjectCreate(0, name, OBJ_TREND, 0, start_time, ExtCloseBuffer[i], end_time, ExtCloseBuffer[i]);
                     }

                     ObjectSetInteger(0, name, OBJPROP_COLOR, colorUltraUp);
                  } else {
                     if (use_high_low) {
                        ObjectCreate(0, name, OBJ_TREND, 0, start_time, ExtLowBuffer[i], end_time, ExtLowBuffer[i]);
                     } else {
                        ObjectCreate(0, name, OBJ_TREND, 0, start_time, ExtOpenBuffer[i], end_time, ExtOpenBuffer[i]);
                     }
                     ObjectSetInteger(0, name, OBJPROP_COLOR, colorUltraDn);
                  }

                  ObjectSetInteger(0, name, OBJPROP_STYLE, estilo);
                  ObjectSetInteger(0, name, OBJPROP_WIDTH, largura);
                  ObjectSetString(0, name, OBJPROP_TOOLTIP,
                                  "Data: " + ExtTimeBuffer[i] +
                                  "\nTamanho: " + DoubleToString(candle_size * 100, 2) + "% (" + DoubleToString(candle_size / tamanho_medio, 2) + "x " +
                                  "média: " + DoubleToString(tamanho_medio * 100, 2) + "%)" +
                                  "\nVolume: " + DoubleToStrCommaSep(volume, 2) + " (" + DoubleToString(volume / media, 2) + "x " +
                                  "média: " + DoubleToStrCommaSep(media, 2) + ")");
               }
            }

         } else if ((volBuffer[i] < media * _VolUltra) && (volBuffer[i] >= media * _VolVeryHigh)) {
            if (drawSR && i > totalRates - limit) {
               ExtColorsBuffer[i] = ExtCloseBuffer[i] >= ExtOpenBuffer[i] ? 2 : 7;
               string name = "vol_bull_" + p_ativo + "_" + p_volume + "_" + i;
               if (ExtCloseBuffer[i] >= ExtOpenBuffer[i]) {
                  if (use_high_low) {
                     ObjectCreate(0, name, OBJ_TREND, 0, start_time, ExtHighBuffer[i], end_time, ExtHighBuffer[i]);
                  } else {
                     ObjectCreate(0, name, OBJ_TREND, 0, start_time, ExtCloseBuffer[i], end_time, ExtCloseBuffer[i]);
                  }

                  ObjectSetInteger(0, name, OBJPROP_COLOR, colorVeryHighUp);
               } else {
                  if (use_high_low) {
                     ObjectCreate(0, name, OBJ_TREND, 0, start_time, ExtLowBuffer[i], end_time, ExtLowBuffer[i]);
                  } else {
                     ObjectCreate(0, name, OBJ_TREND, 0, start_time, ExtOpenBuffer[i], end_time, ExtOpenBuffer[i]);
                  }
                  ObjectSetInteger(0, name, OBJPROP_COLOR, colorVeryHighDn);
               }

               ObjectSetInteger(0, name, OBJPROP_STYLE, estilo);
               ObjectSetInteger(0, name, OBJPROP_WIDTH, largura);
               ObjectSetString(0, name, OBJPROP_TOOLTIP,
                               "Data: " + ExtTimeBuffer[i] +
                               "\nTamanho: " + DoubleToString(candle_size * 100, 2) + "% (" + DoubleToString(candle_size / tamanho_medio, 2) + "x " +
                               "média: " + DoubleToString(tamanho_medio * 100, 2) + "%)" +
                               "\nVolume: " + DoubleToStrCommaSep(volume, 2) + " (" + DoubleToString(volume / media, 2) + "x " +
                               "média: " + DoubleToStrCommaSep(media, 2) + ")");
            }
            //if (drawSR) {
            //   ObjectCreate(0, "vol_top_vh_" + i, OBJ_HLINE, 0, iTime(NULL, inpTimeframe, i), ExtHighBuffer[i]);
            //   ObjectSetInteger(0, "vol_top_vh_" + i, OBJPROP_COLOR, colorVeryHighUp);
            //   ObjectCreate(0, "vol_bottom_vh_" + i, OBJ_HLINE, 0, iTime(NULL, inpTimeframe, i), ExtLowBuffer[i]);
            //   ObjectSetInteger(0, "vol_bottom_vh_" + i, OBJPROP_COLOR, colorVeryHighUp);
            //}
         } else if ((volBuffer[i] < media * _VolVeryHigh) && (volBuffer[i] >= media * _VolHigh)) {
            ExtColorsBuffer[i] = ExtCloseBuffer[i] >= ExtOpenBuffer[i] ? 3 : 8;
         } else if ((volBuffer[i] < media * _VolHigh) && (volBuffer[i] >= media * _VolMedium)) {
            ExtColorsBuffer[i] = 4;
         } else if ((volBuffer[i] < media * _VolMedium) && (volBuffer[i] >= media * _VolLow)) {
            ExtColorsBuffer[i] = 5;
         }
      }


   }
   int a = 0;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update() {

   string temp = StringSubstr(_Symbol, 0, 4);
   if (temp == "DOL$" || temp == "WDO$" || temp == "IND$" || temp == "WIN$" || temp == "DI1$") {
      if (enable_real) {
         drawSR(temp + "N", "real");
         drawSR(temp, "real");
      }

      if (enable_tick) {
         drawSR(temp + "N", "tick");
         drawSR(temp, "tick");
      }
   } else {
      if (enable_real)
         drawSR(_Symbol, "real");

      if (enable_tick)
         drawSR(_Symbol, "tick");
   }

   return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   ObjectsDeleteAll(0, "vol_bull_");
   ObjectsDeleteAll(0, "vol_bear_");
//   for (int i = totalRates - 1; i > totalRates; i--) {
//      ObjectDelete(0, "vol_bull_" + i);
//      ObjectDelete(0, "vol_bear_" + i);
//
//   }
   delete(_updateTimer);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {
 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool _lastOK = false;
MillisecondTimer *_updateTimer;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long & lparam, const double & dparam, const string & sparam) {

//   if(id == CHARTEVENT_CHART_CHANGE) {
//      ObjectsDeleteAll(0, "vol_bull_");
//      ObjectsDeleteAll(0, "vol_bear_");
//      return;
//
//   }
}

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string DoubleToStrCommaSep(double v, int decimals = 4, string s = "") { // 6,454.23

   string abbr = "";
//Septillion: Y; sextillion: Z; Quintillion: E; Quadrillion: Q; Trillion: T; Billion: B; Million: M;
//if (v > 999999999999999999999999) { v = v/1000000000000000000000000; abbr = "Y"; } else
//if (v > 999999999999999999999) { v = v/1000000000000000000000; abbr = "Z"; } else
//if (v > 999999999999999999) { v = v/1000000000000000000; abbr = "E"; } else
//if (v > 999999999999999) { v = v/1000000000000000; abbr = "Q";} else
   if (v > 999999999999) {
      v = v / 1000000000000;
      abbr = "T";
   } else if (v > 999999999) {
      v = v / 1000000000;
      abbr = "B";
   } else if (v > 999999) {
      v = v / 1000000;
      abbr = "M";
   } else if (v > 999) {
      v = v / 1000;
      abbr = "K";
   }


   v = NormalizeDouble(v, decimals);
   int integer = v;

   if (decimals == 0) {
      return( IntToStrCommaSep(v, s) + abbr);
   } else {
      string fraction = StringSubstr(DoubleToString(v - integer, decimals), 1);
      return(IntToStrCommaSep(integer, s) + fraction + abbr);
   }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string IntToStrCommaSep(int integer, string s = "") {

   string right;
   if(integer < 0) {
      s = "-";
      integer = -integer;
   }

   for(right = ""; integer >= 1000; integer /= 1000)
      right = "," + RJust(integer % 1000, 3, "0") + right;

   return(s + integer + right);

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string RJust(string s, int size, string fill = "0") {
   while( StringLen(s) < size )
      s = fill + s;
   return(s);
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
