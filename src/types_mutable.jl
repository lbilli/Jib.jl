mutable struct Contract
  conId::Int
  symbol::String
  secType::String
  lastTradeDateOrContractMonth::String
  strike::Float64
  right::String
  multiplier::String
  exchange::String
  primaryExchange::String
  currency::String
  localSymbol::String
  tradingClass::String
  includeExpired::Bool
  secIdType::String
  secId::String
  description::String
  issuerId::String
  lastTradeDate::String
  comboLegsDescrip::String
  comboLegs::Vector{ComboLeg}
  deltaNeutralContract::Union{DeltaNeutralContract,Nothing}
end
Contract(; conId=        0,
           symbol=      ns,
           secType=     ns,
           exchange=    ns,
           currency=    ns,
           localSymbol= ns) = Contract(conId, symbol, secType, ns, 0.0, ns, ns,
                                       exchange, ns, currency, localSymbol, ns,
                                       false, ns, ns, ns, ns, ns, ns, ComboLeg[], nothing)


mutable struct Order
  orderId::Int
  clientId::Int
  permId::Int
  action::String
  totalQuantity::Float64
  orderType::String
  lmtPrice::Union{Float64,Nothing}
  auxPrice::Union{Float64,Nothing}
  tif::String
  activeStartTime::String
  activeStopTime::String
  ocaGroup::String
  ocaType::Int
  orderRef::String
  transmit::Bool
  parentId::Int
  blockOrder::Bool
  sweepToFill::Bool
  displaySize::Union{Int,Nothing}
  triggerMethod::Int
  outsideRth::Bool
  hidden::Bool
  goodAfterTime::String
  goodTillDate::String
  rule80A::String
  allOrNone::Bool
  minQty::Union{Int,Nothing}
  percentOffset::Union{Float64,Nothing}
  overridePercentageConstraints::Bool
  trailStopPrice::Union{Float64,Nothing}
  trailingPercent::Union{Float64,Nothing}
  faGroup::String
  faMethod::String
  faPercentage::String
  openClose::String
  origin::Origin
  shortSaleSlot::Int
  designatedLocation::String
  exemptCode::Int
  discretionaryAmt::Float64
  optOutSmartRouting::Bool
  auctionStrategy::AuctionStrategy
  startingPrice::Union{Float64,Nothing}
  stockRefPrice::Union{Float64,Nothing}
  delta::Union{Float64,Nothing}
  stockRangeLower::Union{Float64,Nothing}
  stockRangeUpper::Union{Float64,Nothing}
  randomizeSize::Bool
  randomizePrice::Bool
  volatility::Union{Float64,Nothing}
  volatilityType::Union{Int,Nothing}
  deltaNeutralOrderType::String
  deltaNeutralAuxPrice::Union{Float64,Nothing}
  deltaNeutralConId::Int
  deltaNeutralSettlingFirm::String
  deltaNeutralClearingAccount::String
  deltaNeutralClearingIntent::String
  deltaNeutralOpenClose::String
  deltaNeutralShortSale::Bool
  deltaNeutralShortSaleSlot::Int
  deltaNeutralDesignatedLocation::String
  continuousUpdate::Bool
  referencePriceType::Union{Int,Nothing}
  basisPoints::Union{Float64,Nothing}
  basisPointsType::Union{Int,Nothing}
  scaleInitLevelSize::Union{Int,Nothing}
  scaleSubsLevelSize::Union{Int,Nothing}
  scalePriceIncrement::Union{Float64,Nothing}
  scalePriceAdjustValue::Union{Float64,Nothing}
  scalePriceAdjustInterval::Union{Int,Nothing}
  scaleProfitOffset::Union{Float64,Nothing}
  scaleAutoReset::Bool
  scaleInitPosition::Union{Int,Nothing}
  scaleInitFillQty::Union{Int,Nothing}
  scaleRandomPercent::Bool
  scaleTable::String
  hedgeType::String
  hedgeParam::String
  account::String
  settlingFirm::String
  clearingAccount::String
  clearingIntent::String
  algoStrategy::String
  algoParams::NamedTuple
  smartComboRoutingParams::NamedTuple
  algoId::String
  whatIf::Bool
  notHeld::Bool
  solicited::Bool
  modelCode::String
  orderComboLegs::Vector{Float64}
  orderMiscOptions::NamedTuple
  referenceContractId::Int
  peggedChangeAmount::Float64
  isPeggedChangeAmountDecrease::Bool
  referenceChangeAmount::Float64
  referenceExchangeId::String
  adjustedOrderType::String
  triggerPrice::Union{Float64,Nothing}
  adjustedStopPrice::Union{Float64,Nothing}
  adjustedStopLimitPrice::Union{Float64,Nothing}
  adjustedTrailingAmount::Union{Float64,Nothing}
  adjustableTrailingUnit::Int
  lmtPriceOffset::Union{Float64,Nothing}
  conditions::Vector{AbstractCondition}
  conditionsCancelOrder::Bool
  conditionsIgnoreRth::Bool
  extOperator::String
  softDollarTier::SoftDollarTier
  cashQty::Union{Float64,Nothing}
  mifid2DecisionMaker::String
  mifid2DecisionAlgo::String
  mifid2ExecutionTrader::String
  mifid2ExecutionAlgo::String
  dontUseAutoPriceForHedge::Bool
  isOmsContainer::Bool
  discretionaryUpToLimitPrice::Bool
  autoCancelDate::String
  filledQuantity::Union{Float64,Nothing}
  refFuturesConId::Union{Int,Nothing}
  autoCancelParent::Bool
  shareholder::String
  imbalanceOnly::Bool
  routeMarketableToBbo::Bool
  parentPermId::Union{Int,Nothing}
  usePriceMgmtAlgo::Union{Bool,Nothing}
  duration::Union{Int,Nothing}
  postToAts::Union{Int,Nothing}
  advancedErrorOverride::String
  manualOrderTime::String
  minTradeQty::Union{Int,Nothing}
  minCompeteSize::Union{Int,Nothing}
  competeAgainstBestOffset::Union{Float64,Nothing}
  midOffsetAtWhole::Union{Float64,Nothing}
  midOffsetAtHalf::Union{Float64,Nothing}
  customerAccount::String
  professionalCustomer::Bool
  bondAccruedInterest::String
  includeOvernight::Bool
  manualOrderIndicator::Union{Int,Nothing}
end
Order() = Order(0, 0, 0, ns, 0, ns, nothing, nothing, ns, ns, ns, ns, 0, ns, true, 0,
                false, false, nothing, 0, false, false, ns, ns, ns, false, nothing, nothing,
                false, nothing, nothing, ns, ns, ns, ns, CUSTOMER, 0, ns, -1, 0,
                false, UNSET, fill(nothing, 5)..., false, false,
                nothing, nothing, ns, nothing, 0, ns, ns, ns, ns, false, 0, ns, false,
                fill(nothing, 9)..., false, nothing, nothing, false, fill(ns, 8)...,
                (;), (;), ns, false, false, false, ns, Float64[], (;), 0, 0, false, 0, ns, ns,
                fill(nothing, 4)..., 0, nothing, AbstractCondition[], false, false, ns,
                SoftDollarTier(), nothing, ns, ns, ns, ns, false, false, false, ns, nothing,
                nothing, false, ns, false, false, fill(nothing, 4)..., ns, ns,
                fill(nothing, 5)..., ns, false, ns, false, nothing)


mutable struct ScannerSubscription
  numberOfRows::Int
  instrument::String
  locationCode::String
  scanCode::String
  abovePrice::Union{Float64,Nothing}
  belowPrice::Union{Float64,Nothing}
  aboveVolume::Union{Int,Nothing}
  marketCapAbove::Union{Float64,Nothing}
  marketCapBelow::Union{Float64,Nothing}
  moodyRatingAbove::String
  moodyRatingBelow::String
  spRatingAbove::String
  spRatingBelow::String
  maturityDateAbove::String
  maturityDateBelow::String
  couponRateAbove::Union{Float64,Nothing}
  couponRateBelow::Union{Float64,Nothing}
  excludeConvertible::Bool
  averageOptionVolumeAbove::Union{Int,Nothing}
  scannerSettingPairs::String
  stockTypeFilter::String
end
ScannerSubscription() = ScannerSubscription(-1, ns, ns, ns, fill(nothing, 5)..., fill(ns, 6)...,
                                            nothing, nothing, false, nothing, ns, ns)
