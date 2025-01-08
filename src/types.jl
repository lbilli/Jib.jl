const ns = ""

struct ComboLeg
  conId::Int
  ratio::Int
  action::String
  exchange::String
  openClose::LegOpenClose
  shortSaleSlot::Int
  designatedLocation::String
  exemptCode::Int
end
ComboLeg(; conId=     0,
           ratio=     0,
           action=   ns,
           exchange= ns) = ComboLeg(conId, ratio, action, exchange, SAME, 0, ns, -1)


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
end
ExecutionFilter(; clientId=  0,
                  acctCode= ns,
                  time=     ns,
                  symbol=   ns,
                  secType=  ns,
                  exchange= ns,
                  side=     ns) = ExecutionFilter(clientId, acctCode, time, symbol, secType, exchange, side)

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
OrderCancel(manualOrderCancelTime="") = OrderCancel(manualOrderCancelTime, "", nothing)

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
WshEventData(conId::Int, args...) = WshEventData(conId, "", args...)
WshEventData(filter::String, args...) = WshEventData(nothing, filter, args...)
