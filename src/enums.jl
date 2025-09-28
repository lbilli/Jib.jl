@enum AuctionStrategy UNSET MATCH IMPROVEMENT TRANSPARENT

@enum FaDataType GROUPS=1 ALIASES=3

@enum LegOpenClose SAME OPEN CLOSE UNKNOWN_POS

@enum MarketDataType REALTIME=1 FROZEN=2 DELAYED=3 DELAYED_FROZEN=4

@enum Origin CUSTOMER FIRM UNKNOWN

@enum ConditionType PRICE=1 TIME=3 MARGIN=4 EXECUTION=5 VOLUME=6 PERCENTCHANGE=7


funddist(v) = v == "N" ? "Accumulation Fund" :
              v == "Y" ? "Income Fund"       :
                         "None"

fundtype(v) = v == "000" ? "Others"       :
              v == "001" ? "Money Market" :
              v == "002" ? "Fixed Income" :
              v == "003" ? "Multi-asset"  :
              v == "004" ? "Equity"       :
              v == "005" ? "Sector"       :
              v == "006" ? "Guaranteed"   :
              v == "007" ? "Alternative"  :
                           "None"

optexercisetype(v) = v ==  -1 ? "None" :
                     v ==   1 ? "Exercise" :
                     v ==   2 ? "Lapse"    :
                     v ==   3 ? "DoNothing" :
                     v == 100 ? "Assigned"  :
                     v == 101 ? "AutoexerciseClearing" :
                     v == 102 ? "Expired"              :
                     v == 103 ? "Netting"              :
                     v == 200 ? "AutoexerciseTrading"  :
                                (@warn("unknown type", v); "None")
