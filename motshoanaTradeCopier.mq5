#define FILE_NAME MQLInfoString(MQL_PROGRAM_NAME)
#include <trade/trade.mqh>
#include <arrays/arraylong.mqh>

enum ENUM_MODE {MODE_MASTER, MODE_SLAVE};
input ENUM_MODE Mode = MODE_SLAVE;

CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   //EventSetMillisecondTimer(500);
   EventSetTimer(1);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   EventKillTimer();
  }
  void OnTimer(){
     if(Mode == MODE_MASTER){
           int f = FileOpen(FILE_NAME,FILE_WRITE|FILE_BIN|FILE_COMMON);
           if (f != INVALID_HANDLE){
           
               if(PositionsTotal() == 0 ){
                     //FileDelete(FILE_NAME);
                     
                  } else {
                      for ( int i = PositionsTotal() - 1; i >= 0; i--) {
                      
                            CPositionInfo p;
                            if(p.SelectByIndex(i)){
                            
                                 FileWriteLong(f, p.Ticket());
                                 int l = StringLen(p.Symbol());
                                 FileWriteInteger(f,l);
                                 FileWriteString(f,p.Symbol());
                                 FileWriteDouble(f,p.Volume());
                                 FileWriteInteger(f,p.PositionType());
                                 FileWriteDouble(f,p.PriceOpen());
                                 FileWriteDouble(f,p.StopLoss());
                                 FileWriteDouble(f,p.TakeProfit());
                  
                            }
                            
                      }
               }
               FileClose(f);
           }
           
     }else if(Mode == MODE_SLAVE){
        CArrayLong a;
        a.Sort();
        
        int f = FileOpen(FILE_NAME, FILE_READ|FILE_BIN|FILE_COMMON);
        if(f != INVALID_HANDLE){
            while(!FileIsEnding(f)){
            
                  ulong pTicket = FileReadLong(f);
                  int length= FileReadInteger(f);
                  string pSymbol = FileReadString(f, length);
                  double pVolume = FileReadDouble(f);
                  
                  ENUM_POSITION_TYPE pType = (ENUM_POSITION_TYPE)FileReadInteger(f);
                
                  double pPriceOpen = FileReadDouble(f);
                  double pStopLoss = FileReadDouble(f);
                  double pTakeProfit = FileReadDouble(f);
                  
                  for ( int i = PositionsTotal() - 1; i >= 0; i--) {
                      
                        CPositionInfo p;
                        if(p.SelectByIndex(i)){
                              
                            if(StringToInteger(p.Comment()) == pTicket){
                               
                                 if(a.SearchFirst(pTicket) < 0){
                                    a.InsertSort(pTicket);
                                 }
                                 
                                 if(p.StopLoss() != pStopLoss || p.TakeProfit() != pTakeProfit){
                                    trade.PositionModify(p.Ticket(), pStopLoss, pTakeProfit);
                                    
                                 }
                                 
                                 break;
                             }
                         }    
                  }
                  if(a.SearchFirst(pTicket) < 0){
                  
                     if(pType == POSITION_TYPE_BUY){
                     
                        trade.Buy(pVolume, pSymbol,0,pStopLoss,pTakeProfit, IntegerToString(pTicket));
                        
                     } else if (pType == POSITION_TYPE_SELL){
                        trade.Sell(pVolume,pSymbol,0,pStopLoss,pTakeProfit, IntegerToString(pTicket));
                     }
                     
                     if(trade.ResultRetcode() == TRADE_RETCODE_DONE) a.InsertSort(pTicket);
                
                  }
                  
            }
            
            FileClose(f);
            
            for(int i = PositionsTotal(); i >= 0; i--) {
              CPositionInfo p;
              if(p.SelectByIndex(i)){
                  if(a.SearchFirst(StringToInteger(p.Comment())) < 0){
                     trade.PositionClose(p.Ticket());
                      
                  }
              }
            }
        }
        
     }
  }
 
  
