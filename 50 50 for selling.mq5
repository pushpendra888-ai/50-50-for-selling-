#include <Trade\Trade.mqh>
#property strict

input double lotSize         = 0.01;
input double targetProfitUSD = 0.30;   // reduced profit target
input double maxLossUSD      = -1.50;  // maximum loss allowed
input long   magicNumber     = 2002;   // unique ID for this EA

CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   // ensure CTrade sends orders with this EA's magic number
   trade.SetExpertMagicNumber(magicNumber);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick                                                       |
//+------------------------------------------------------------------+
void OnTick()
{
   bool sellPositionExists = false;

   // Loop through all open positions (safely)
   for(int idx = PositionsTotal() - 1; idx >= 0; idx--)
   {
      // get ticket by index
      ulong ticket = PositionGetTicket(idx);
      if(ticket == 0) continue;

      // select that position by ticket so PositionGet* functions work
      if(!PositionSelectByTicket(ticket)) continue;

      // check if it's our symbol, our magic and a SELL position
      string sym = PositionGetString(POSITION_SYMBOL);
      long   type = (long)PositionGetInteger(POSITION_TYPE);
      long   mag  = (long)PositionGetInteger(POSITION_MAGIC);

      if(sym == _Symbol && type == POSITION_TYPE_SELL && mag == magicNumber)
      {
         sellPositionExists = true;

         double profit = PositionGetDouble(POSITION_PROFIT);

         // close if profit target reached or loss exceeded
         if(profit >= targetProfitUSD || profit <= maxLossUSD)
         {
            trade.PositionClose(ticket);
            sellPositionExists = false; // will open again later if needed
         }
      }
   }

   // If no sell position exists for this EA, open a new market sell
   if(!sellPositionExists)
   {
      bool ok = trade.Sell(lotSize, _Symbol);
      if(ok)
         PrintFormat("Sell opened (magic=%d, lots=%.2f)", magicNumber, lotSize);
      else
         Print("Sell open failed: ", GetLastError());
   }
}
