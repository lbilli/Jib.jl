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


struct IneligibilityReason
  id::String
  description::String
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
  aggGroup::Union{Int,Nothing}
  underSymbol::String
  underSecType::String
  marketRuleIds::String
  realExpirationDate::String
  lastTradeTime::String
  stockType::String
  minSize::Union{Float64,Nothing}
  sizeIncrement::Union{Float64,Nothing}
  suggestedSizeIncrement::Union{Float64,Nothing}
  secIdList::NamedTuple
  cusip::String
  ratings::String
  descAppend::String
  bondType::String
  couponType::String
  callable::Bool
  putable::Bool
  coupon::Union{Float64,Nothing}
  convertible::Bool
  maturity::String
  issueDate::String
  nextOptionDate::String
  nextOptionType::String
  nextOptionPartial::Bool
  notes::String
  fundName::String
  fundFamily::String
  fundType::String
  fundFrontLoad::String
  fundBackLoad::String
  fundBackLoadTimeInterval::String
  fundManagementFee::String
  fundClosed::Bool
  fundClosedForNewInvestors::Bool
  fundClosedForNewMoney::Bool
  fundNotifyAmount::String
  fundMinimumInitialPurchase::String
  fundSubsequentMinimumPurchase::String
  fundBlueSkyStates::String
  fundBlueSkyTerritories::String
  fundDistributionPolicyIndicator::String
  fundAssetType::String
  ineligibilityReasonList::Vector{IneligibilityReason}
end
ContractDetails() = ContractDetails(Contract(), ns, 0, ns, ns, 0, 0, fill(ns, 9)...,
                                    nothing, nothing, fill(ns, 6)..., nothing, nothing,
                                    nothing, (;), fill(ns, 5)..., false, false,
                                    nothing, false, ns, ns, ns, ns, false, ns,
                                    fill(ns, 7)..., false, false, false, fill(ns, 7)...,
                                    IneligibilityReason[])


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
  lastLiquidity::Union{Int,Nothing}
  pendingPriceRevision::Bool
end


struct OrderAllocation
  account::String
  position::Float64
  positionDesired::Float64
  positionAfter::Float64
  desiredAllocQty::Float64
  allowedAllocQty::Float64
  isMonetary::Bool
end


mutable struct OrderState
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
  marginCurrency::String
  initMarginBeforeOutsideRTH::Union{Float64,Nothing}
  maintMarginBeforeOutsideRTH::Union{Float64,Nothing}
  equityWithLoanBeforeOutsideRTH::Union{Float64,Nothing}
  initMarginChangeOutsideRTH::Union{Float64,Nothing}
  maintMarginChangeOutsideRTH::Union{Float64,Nothing}
  equityWithLoanChangeOutsideRTH::Union{Float64,Nothing}
  initMarginAfterOutsideRTH::Union{Float64,Nothing}
  maintMarginAfterOutsideRTH::Union{Float64,Nothing}
  equityWithLoanAfterOutsideRTH::Union{Float64,Nothing}
  suggestedSize::Union{Float64,Nothing}
  rejectReason::String
  orderAllocations::Vector{OrderAllocation}
  warningText::String
  completedTime::String
  completedStatus::String
end
OrderState() = OrderState(fill(ns, 10)..., fill(nothing, 3)..., ns, ns,
                          fill(nothing, 10)..., ns, OrderAllocation[],
                          ns, ns, ns)


TickAttrib =       NamedTuple{(:canAutoExecute, :pastLimit, :preOpen),NTuple{3,Bool}}
TickAttribLast =   NamedTuple{(:pastLimit, :unreported),NTuple{2,Bool}}
TickAttribBidAsk = NamedTuple{(:bidPastLow, :askPastHigh),NTuple{2,Bool}}


Bar = @NamedTuple{time::String, open::Float64, high::Float64, low::Float64, close::Float64,
                  volume::Float64, wap::Float64, count::Int}

VBar = Vector{Bar}

VDepthMktDataDescription = Vector{@NamedTuple{exchange::String, secType::String,
                                              listingExch::String, serviceDataType::String,
                                              aggGroup::Union{Int,Nothing}}}

VFamilyCode =        Vector{@NamedTuple{accountID::String, familyCodeStr::String}}
VHistogramEntry =    Vector{@NamedTuple{price::Float64, size::Float64}}
VHistoricalSession = Vector{@NamedTuple{startDateTime::String, endDateTime::String, refDate::String}}

HistoricalTick =     @NamedTuple{time::Int, price::Float64, size::Float64}
VHistoricalTick =    Vector{HistoricalTick}

VHistoricalTickBidAsk = Vector{@NamedTuple{time::Int, mask::TickAttribBidAsk,
                                           priceBid::Float64, priceAsk::Float64,
                                           sizeBid::Float64, sizeAsk::Float64}}

VHistoricalTickLast = Vector{@NamedTuple{time::Int, mask::TickAttribLast,
                                         price::Float64, size::Float64,
                                         exchange::String, specialConditions::String}}

VPriceIncrement = Vector{@NamedTuple{lowEdge::Float64, increment::Float64}}
VNewsProvider =   Vector{@NamedTuple{providerCode::String, providerName::String}}
VSmartComponent = Vector{@NamedTuple{bit::Int, exchange::String, exchangeLetter::String}}
