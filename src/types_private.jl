struct CommissionReport
  execId::String
  commission::Float64
  currency::String
  realizedPNL::Union{Float64,Nothing}
  yield::Union{Float64,Nothing}
  yieldRedemptionDate::Union{Int,Nothing}
end


struct ContractDescription
  contract::Contract
  derivativeSecTypes::Vector{String}
end


mutable struct ContractDetails
  contract::Contract
  marketName::String
  minTick::Float64
  orderTypes::String
  validExchanges::String
  priceMagnifier::Int
  underConId::Int
  longName::String
  contractMonth::String
  industry::String
  category::String
  subcategory::String
  timeZoneId::String
  tradingHours::String
  liquidHours::String
  evRule::String
  evMultiplier::Union{Float64,Nothing}
  mdSizeMultiplier::Union{Int,Nothing}
  aggGroup::Union{Int,Nothing}
  underSymbol::String
  underSecType::String
  marketRuleIds::String
  realExpirationDate::String
  lastTradeTime::String
  stockType::String
  secIdList::NamedTuple
  cusip::String
  ratings::String
  descAppend::String
  bondType::String
  couponType::String
  callable::Bool
  putable::Bool
  coupon::Float64
  convertible::Bool
  maturity::String
  issueDate::String
  nextOptionDate::String
  nextOptionType::String
  nextOptionPartial::Bool
  notes::String
end
ContractDetails() = ContractDetails(Contract(), ns, 0.0, ns, ns, 0, 0, fill(ns, 9)..., 0,
                                    nothing, nothing, fill(ns, 6)..., (;),
                                    fill(ns, 5)..., false, false, 0, false, ns, ns, ns, ns,
                                    false, ns)


struct Execution
  orderId::Union{Int,Nothing}     # Moved up from position 10 for convenience when constructing
  execId::String
  time::String
  acctNumber::String
  exchange::String
  side::String
  shares::Float64
  price::Float64
  permId::Int
  clientId::Int
  liquidation::Int
  cumQty::Float64
  avgPrice::Float64
  orderRef::String
  evRule::String
  evMultiplier::Union{Float64,Nothing}
  modelCode::String
  lastLiquidity::Int
end


struct FamilyCode
  accountID::String
  familyCodeStr::String
end


struct OrderState
  status::String
  initMarginBefore::String
  maintMarginBefore::String
  equityWithLoanBefore::String
  initMarginChange::String
  maintMarginChange::String
  equityWithLoanChange::String
  initMarginAfter::String
  maintMarginAfter::String
  equityWithLoanAfter::String
  commission::Union{Float64,Nothing}
  minCommission::Union{Float64,Nothing}
  maxCommission::Union{Float64,Nothing}
  commissionCurrency::String
  warningText::String
  completedTime::String
  completedStatus::String
end


TickAttrib =       NamedTuple{(:canAutoExecute, :pastLimit, :preOpen),NTuple{3,Bool}}
TickAttribLast =   NamedTuple{(:pastLimit, :unreported),NTuple{2,Bool}}
TickAttribBidAsk = NamedTuple{(:bidPastLow, :askPastHigh),NTuple{2,Bool}}
