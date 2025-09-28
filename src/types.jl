const ns = ""

struct ComboLeg
  conId::Int
  ratio::Int
  action::String
  exchange::String
  openClose::Int
  shortSaleSlot::Int
  designatedLocation::String
  exemptCode::Int
end
ComboLeg(; conId=     0,
           ratio=     0,
           action=   ns,
           exchange= ns) = ComboLeg(conId, ratio, action, exchange, 0, 0, ns, -1)


struct DeltaNeutralContract
  conId::Int
  delta::Float64
  price::Float64
end


struct ExecutionFilter
  clientId::Int
  acctCode::String
  time::String
  symbol::String
  secType::String
  exchange::String
  side::String
  lastNDays::Union{Int,Nothing}
  specificDates::Vector{Int}
end
ExecutionFilter(; clientId=       0,
                  acctCode=       ns,
                  time=           ns,
                  symbol=         ns,
                  secType=        ns,
                  exchange=       ns,
                  side=           ns,
                  lastNDays=      nothing,
                  specificDates = Int[]) = ExecutionFilter(clientId, acctCode, time, symbol,
                                                           secType, exchange, side, lastNDays,
                                                           specificDates)


struct SoftDollarTier
  name::String
  val::String
  displayName::String
end
SoftDollarTier() = SoftDollarTier(ns, ns, ns)


struct OrderCancel
  manualOrderCancelTime::String
  extOperator::String
  manualOrderIndicator::Union{Int,Nothing}
end
OrderCancel(manualOrderCancelTime=ns) = OrderCancel(manualOrderCancelTime, ns, nothing)


struct WshEventData
  conId::Union{Int,Nothing}
  filter::String
  fillWatchlist::Bool
  fillPortfolio::Bool
  fillCompetitors::Bool
  startDate::String
  endDate::String
  totalLimit::Union{Int,Nothing}
end
WshEventData(; conId=           nothing,
               filter=          ns,
               fillWatchlist=   false,
               fillPortfolio=   false,
               fillCompetitors= false,
               startDate=       ns,
               endDate=         ns,
               totalLimit=      nothing) = WshEventData(conId, filter, fillWatchlist, fillPortfolio,
                                                        fillCompetitors, startDate, endDate, totalLimit)
