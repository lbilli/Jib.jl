using Base.Iterators: take

import InteractiveBrokers

import ...AbstractCondition,
  ...ComboLeg,
  ...CommissionReport,
  ...ConditionType,
  ...Contract,
  ...ContractDescription,
  ...ContractDetails,
  ...DeltaNeutralContract,
  ...Execution,
  ...FaDataType,
  ...IneligibilityReason,
  ...MarketDataType,
  ...Order,
  ...OrderAllocation,
  ...OrderState,
  ...SoftDollarTier,
  ...TickAttrib,
  ...TickAttribLast,
  ...TickAttribBidAsk,
  ...VBar,
  ...VDepthMktDataDescription,
  ...VFamilyCode,
  ...VHistogramEntry,
  ...VHistoricalSession,
  ...HistoricalTick,
  ...VHistoricalTickBidAsk,
  ...VHistoricalTickLast,
  ...VNewsProvider,
  ...VPriceIncrement,
  ...VSmartComponent,
  ...condition_map,
  ...funddist,
  ...fundtype,
  ...ns


"""
    process::Dict{Int,Function}

Collection of parsers indexed by message ID
"""
const process = Dict(

  # TICK_PRICE
  1 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    tickerId::Int,
    ticktype::Int,
    price::Union{Float64,Nothing},
    size::Union{Float64,Nothing},
    mask::TickAttrib = it

    InteractiveBrokers.forward(w, :tickPrice, tickerId, InteractiveBrokers.TickTypes.TICK_TYPES(ticktype), price, size, mask)
  end,

  # TICK_SIZE
  2 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    tickerId::Int,
    ticktype::Int,
    size::Float64 = it

    InteractiveBrokers.forward(w, :tickSize, tickerId, InteractiveBrokers.TickTypes.TICK_TYPES(ticktype), size)
  end,

  # ORDER_STATUS
  3 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :orderStatus, slurp((Int, String, Float64, Float64, Float64, Int, Int, Float64, Int, String, Float64), it)...),

  # ERR_MSG
  4 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver)

    id::Union{Int,Nothing},
    errorCode::Union{Int,Nothing},
    errorMsg::String,
    adv::String = it

    errorTime::Int = ver ≥ Client.ERROR_TIME ? it : 0
    err = InteractiveBrokers.IbkrErrorMessage(id, errorTime, errorCode, errorMsg, adv)

    InteractiveBrokers.forward(w, :error, err)
  end,

  # OPEN_ORDER
  5 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    c = Contract()
    o = Order()
    os = OrderState()

    o.orderId = it

    slurp!(c, [1:8; 10:12], it)

    slurp!(o, 4:9, it) # :action -> :tif

    slurp!(o, (:ocaGroup,
        :account,
        :openClose,
        :origin,
        :orderRef,
        :clientId,
        :permId,
        :outsideRth,
        :hidden,
        :discretionaryAmt,
        :goodAfterTime), it)

    pop(it) # Deprecated sharesAllocation

    slurp!(o, (:faGroup,
        :faMethod,
        :faPercentage,
        :modelCode,
        :goodTillDate,
        :rule80A,
        :percentOffset,
        :settlingFirm,
        :shortSaleSlot,
        :designatedLocation,
        :exemptCode), it)

    slurp!(o, 42:47, it) # :auctionStrategy -> :stockRangeUpper

    slurp!(o, (:displaySize,
        :blockOrder,
        :sweepToFill,
        :allOrNone,
        :minQty,
        :ocaType), it)

    pop(it) # Deprecated eTradeOnly
    pop(it) # Deprecated firmQuoteOnly
    pop(it) # Deprecated nbboPriceCap

    slurp!(o, (:parentId,
        :triggerMethod), it)

    slurp!(o, 50:53, it) # :volatility -> :deltaNeutralAuxPrice

    !isempty(o.deltaNeutralOrderType) && slurp!(o, 54:61, it) # :deltaNeutralConId -> :deltaNeutralDesignatedLocation

    slurp!(o, (:continuousUpdate,
        :referencePriceType,
        :trailStopPrice,
        :trailingPercent,
        :basisPoints,
        :basisPointsType), it)

    c.comboLegsDescrip,
    c.comboLegs = it

    slurp!(o, (:orderComboLegs,
        :smartComboRoutingParams,
        :scaleInitLevelSize,
        :scaleSubsLevelSize,
        :scalePriceIncrement), it)

    !isnothing(o.scalePriceIncrement) &&
      o.scalePriceIncrement > 0 && slurp!(o, 69:75, it) # :scalePriceAdjustValue -> :scaleRandomPercent

    o.hedgeType = it

    !isempty(o.hedgeType) && (o.hedgeParam = it)

    slurp!(o, (:optOutSmartRouting,
        :clearingAccount,
        :clearingIntent,
        :notHeld), it)

    # DeltaNeutralContract
    convert(Bool, it) && (c.deltaNeutralContract = it)

    # AlgoStrategy
    o.algoStrategy = it

    !isempty(o.algoStrategy) && (o.algoParams = it)

    o.solicited,
    o.whatIf = it

    slurp!(os, 1:14, it) # :status -> :commissionCurrency

    ver ≥ Client.FULL_ORDER_PREVIEW_FIELDS &&
      slurp!(os, 15:27, it) # :marginCurrency -> :orderAllocations

    os.warningText,
    o.randomizeSize,
    o.randomizePrice = it

    o.orderType == "PEG BENCH" && slurp!(o, (:referenceContractId,
        :isPeggedChangeAmountDecrease,
        :peggedChangeAmount,
        :referenceChangeAmount,
        :referenceExchangeId), it)

    # Conditions
    o.conditions = it

    if !isempty(o.conditions)
      o.conditionsIgnoreRth,
      o.conditionsCancelOrder = it
    end

    slurp!(o, (:adjustedOrderType,
        :triggerPrice,
        :trailStopPrice,
        :lmtPriceOffset,
        :adjustedStopPrice,
        :adjustedStopLimitPrice,
        :adjustedTrailingAmount,
        :adjustableTrailingUnit,
        :softDollarTier,
        :cashQty,
        :dontUseAutoPriceForHedge,
        :isOmsContainer,
        :discretionaryUpToLimitPrice,
        :usePriceMgmtAlgo,
        :duration,
        :postToAts,
        :autoCancelParent,
        :minTradeQty,
        :minCompeteSize,
        :competeAgainstBestOffset,
        :midOffsetAtWhole,
        :midOffsetAtHalf,
        :customerAccount,
        :professionalCustomer,
        :bondAccruedInterest), it)

    ver ≥ Client.INCLUDE_OVERNIGHT && (o.includeOvernight = it)

    ver ≥ Client.CME_TAGGING_FIELDS_IN_OPEN_ORDER && slurp!(o, (:extOperator,
        :manualOrderIndicator), it)

    ver ≥ Client.BOND_ACCRUED_INTEREST && (o.bondAccruedInterest = pop(it))

    InteractiveBrokers.forward(w, :openOrder, o.orderId, c, o, os)
  end,

  # ACCT_VALUE
  6 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :updateAccountValue, collect(String, take(it, 4))...),

  # PORTFOLIO_VALUE
  7 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    c = Contract()

    slurp!(c, [1:7; 9:12], it)

    forward(w, :updatePortfolio, c, collect(Float64, take(it, 6))..., convert(String, it))
  end,

  # ACCT_UPDATE_TIME
  8 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver) -> forward(w, :updateAccountTime, convert(String, it)),

  # NEXT_VALID_ID
  9 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver) -> forward(w, :nextValidId, convert(Int, it)),

  # CONTRACT_DATA
  10 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int = it

    cd = ContractDetails()

    slurp!(cd.contract, (2, 3, 4, 18, 5, 6, 8, 10, 11), it)

    cd.marketName,
    cd.contract.tradingClass,
    cd.contract.conId,
    cd.minTick,
    cd.contract.multiplier = it

    slurp!(cd, 4:8, it)
    cd.contract.primaryExchange = it
    slurp!(cd, 9:17, it)

    slurp!(cd, (:secIdList,
        :aggGroup,
        :underSymbol,
        :underSecType,
        :marketRuleIds,
        :realExpirationDate,
        :stockType,
        :minSize,
        :sizeIncrement,
        :suggestedSizeIncrement), it)

    if cd.contract.secType == "FUND"

      slurp!(cd, 44:58, it)

      cd.fundDistributionPolicyIndicator = funddist(convert(String, it))
      cd.fundAssetType = fundtype(convert(String, it))
    end

    cd.ineligibilityReasonList = it

    InteractiveBrokers.forward(w, :contractDetails, reqId, cd)
  end,

  # EXECUTION_DATA
  11 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int,
    orderId::Union{Int,Nothing} = it

    c = Contract()
    slurp!(c, [1:8; 10:12], it)

    e = Execution(orderId, take(it, 18)...)

    InteractiveBrokers.forward(w, :execDetails, reqId, c, e)
  end,

  # MARKET_DEPTH
  12 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :updateMktDepth, slurp((Int, Int, Int, Int, Float64, Float64), it)...),

  # MARKET_DEPTH_L2
  13 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :updateMktDepthL2, slurp((Int, Int, String, Int, Int, Float64, Float64, Bool), it)...),

  # NEWS_BULLETINS
  14 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :updateNewsBulletin, slurp((Int, Int, String, String), it)...),

  # MANAGED_ACCTS
  15 => (it, w, ver) -> InteractiveBrokers.forward(w, :managedAccounts, convert(String, it)),

  # RECEIVE_FA
  16 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :receiveFA, slurp((FaDataType, String), it)...),

  # HISTORICAL_DATA
  17 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int = it

    if ver < Client.HISTORICAL_DATA_END
      pop(it) # Ignore startDate
      pop(it) # Ignore endDate
    end

    bars::VBar = it

    InteractiveBrokers.forward(w, :historicalData, reqId, bars)
  end,

  # BOND_CONTRACT_DATA
  18 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int = it

    cd = ContractDetails()

    slurp!(cd.contract, 2:3, it)

    slurp!(cd, (:cusip,
        :coupon,
        :maturity,
        :issueDate,
        :ratings,
        :bondType,
        :couponType,
        :convertible,
        :callable,
        :putable,
        :descAppend), it)

    cd.contract.exchange,
    cd.contract.currency,
    cd.marketName,
    cd.contract.tradingClass,
    cd.contract.conId = it

    slurp!(cd, (:minTick,
        :orderTypes,
        :validExchanges,
        :nextOptionDate,
        :nextOptionType,
        :nextOptionPartial,
        :notes,
        :longName), it)

    ver ≥ Client.BOND_TRADING_HOURS && slurp!(cd, 13:15, it) # :timeZoneId -> :liquidHours

    slurp!(cd, 16:17, it) # :evRule -> :evMultiplier

    slurp!(cd, (:secIdList,
        :aggGroup,
        :marketRuleIds,
        :minSize,
        :sizeIncrement,
        :suggestedSizeIncrement), it)

    InteractiveBrokers.forward(w, :bondContractDetails, reqId, cd)
  end,

  # SCANNER_PARAMETERS
  19 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver) -> forward(w, :scannerParameters, convert(String, it)),

  # SCANNER_DATA
  20 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    tickerId::Int,
    n::Int = it

    rank = Vector{Int}(undef, n)
    cd = [ContractDetails() for _ ∈ 1:n]
    distance = Vector{String}(undef, n)
    benchmark = Vector{String}(undef, n)
    projection = Vector{String}(undef, n)
    legsStr = Vector{String}(undef, n)

    for i ∈ 1:n

      rank[i] = it

      slurp!(cd[i].contract, [1:6; 8; 10; 11], it)

      cd[i].marketName,
      cd[i].contract.tradingClass,
      distance[i],
      benchmark[i],
      projection[i],
      legsStr[i] = it
    end

    InteractiveBrokers.forward(w, :scannerData, tickerId, rank, cd, distance, benchmark, projection, legsStr)
  end,

  # TICK_OPTION_COMPUTATION
  21 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    tickerId::Int,
    ticktype::Int,
    tickAttrib::Int = it

    v = collect(Union{Float64,Nothing}, take(it, 8))

    # (impliedVol, optPrice, pvDividend, undPrice) == -1 means NA
    replace!(view(v, [1, 3, 4, 8]), -1 => nothing)

    # (delta, gamma, vega, theta) == -2 means NA
    replace!(view(v, [2, 5, 6, 7]), -2 => nothing)

    InteractiveBrokers.forward(w, :tickOptionComputation, tickerId, InteractiveBrokers.TickTypes.TICK_TYPES(ticktype), tickAttrib, v...)
  end,

  # TICK_GENERIC
  45 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    tickerId::Int,
    ticktype::Int,
    value::Float64 = it

    InteractiveBrokers.forward(w, :tickGeneric, tickerId, InteractiveBrokers.TickTypes.TICK_TYPES(ticktype), value)
  end,

  # TICK_STRING
  46 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    tickerId::Int,
    ticktype::Int,
    value::String = it

    InteractiveBrokers.forward(w, :tickString, tickerId, InteractiveBrokers.TickTypes.TICK_TYPES(ticktype), value)
  end,

  # TICK_EFP
  47 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    tickerId::Int,
    ticktype::Int = it

    InteractiveBrokers.forward(w, tickEFP, tickerId, InteractiveBrokers.TickTypes.TICK_TYPES(ticktype), slurp((Float64, String, Float64, Int, String, Float64, Float64), it)...)
  end,

  # CURRENT_TIME
  49 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :currentTime, convert(Int, it)),

  # REAL_TIME_BARS
  50 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :realtimeBar, slurp((Int, Int, Float64, Float64, Float64, Float64, Float64, Float64, Int), it)...),

  # FUNDAMENTAL_DATA
  51 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :fundamentalData, slurp((Int, String), it)...),

  # CONTRACT_DATA_END
  52 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :contractDetailsEnd, convert(Int, it)),

  # OPEN_ORDER_END
  53 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :openOrderEnd),

  # ACCT_DOWNLOAD_END
  54 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :accountDownloadEnd, convert(String, it)),

  # EXECUTION_DATA_END
  55 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :execDetailsEnd, convert(Int, it)),

  # DELTA_NEUTRAL_VALIDATION
  56 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int = it

    InteractiveBrokers.forward(w, :deltaNeutralValidation, reqId, slurp((Int, DeltaNeutralContract), it)...)
  end,

  # TICK_SNAPSHOT_END
  57 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :tickSnapshotEnd, convert(Int, it)),

  # MARKET_DATA_TYPE
  58 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :marketDataType, slurp((Int, MarketDataType), it)...),

  # COMMISSION_REPORT
  59 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :commissionReport, convert(CommissionReport, it)),

  # POSITION_DATA
  61 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    account::String = it

    c = Contract()
    slurp!(c, [1:8; 10:12], it)

    InteractiveBrokers.forward(w, :position, account, c, slurp((Float64, Float64), it)...)
  end,

  # POSITION_END
  62 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :positionEnd),

  # ACCOUNT_SUMMARY
  63 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int = it

    InteractiveBrokers.forward(w, :accountSummary, reqId, collect(String, take(it, 4))...)
  end,

  # ACCOUNT_SUMMARY_END
  64 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :accountSummaryEnd, convert(Int, it)),

  # VERIFY_MESSAGE_API
  65 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :verifyMessageAPI, convert(String, it)),

  # VERIFY_COMPLETED
  66 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :verifyCompleted, slurp((Bool, String), it)...),

  # DISPLAY_GROUP_LIST
  67 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :displayGroupList, slurp((Int, String), it)...),

  # DISPLAY_GROUP_UPDATED
  68 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :displayGroupUpdated, slurp((Int, String), it)...),

  # VERIFY_AND_AUTH_MESSAGE_API
  69 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :verifyAndAuthMessageAPI, slurp((String, String), it)...),

  # VERIFY_AND_AUTH_COMPLETED
  70 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :verifyAndAuthCompleted, slurp((Bool, String), it)...),

  # POSITION_MULTI
  71 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int,
    account::String = it

    c = Contract()
    slurp!(c, [1:8; 10:12], it)

    position::Float64,
    avgCost::Float64,
    modelCode::String = it

    InteractiveBrokers.forward(w, :positionMulti, reqId, account, modelCode, c, position, avgCost)
  end,

  # POSITION_MULTI_END
  72 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :positionMultiEnd, convert(Int, it)),

  # ACCOUNT_UPDATE_MULTI
  73 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :accountUpdateMulti, convert(Int, it), collect(String, take(it, 5))...),

  # ACCOUNT_UPDATE_MULTI_END
  74 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :accountUpdateMultiEnd, convert(Int, it)),

  # SECURITY_DEFINITION_OPTION_PARAMETER
  75 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    args = slurp((Int, String, Int, String, String), it)

    expirations::Vector{String},
    strikes::Vector{Float64} = it

    InteractiveBrokers.forward(w, :securityDefinitionOptionalParameter, args..., expirations, strikes)
  end,

  # SECURITY_DEFINITION_OPTION_PARAMETER_END
  76 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :securityDefinitionOptionalParameterEnd, convert(Int, it)),

  # SOFT_DOLLAR_TIERS
  77 => (it, w, ver) -> forward(w, :softDollarTiers, slurp((Int, Vector{SoftDollarTier}), it)...),

  # FAMILY_CODES
  78 => (it, w, ver) -> InteractiveBrokers.forward(w, :familyCodes, convert(VFamilyCode, it)),

  # SYMBOL_SAMPLES
  79 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int,
    n::Int = it

    cd = map(1:n) do _

      c = Contract()

      slurp!(c, (:conId,
          :symbol,
          :secType,
          :primaryExchange,
          :currency), it)

      nd::Int = it

      dst = collect(String, take(it, nd))

      c.description,
      c.issuerId = it

      ContractDescription(c, dst)
    end

    InteractiveBrokers.forward(w, :symbolSamples, reqId, cd)
  end,

  # MKT_DEPTH_EXCHANGES
  80 => (it, w, ver) -> InteractiveBrokers.forward(w, :mktDepthExchanges, convert(VDepthMktDataDescription, it)),

  # TICK_REQ_PARAMS
  81 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :tickReqParams, slurp((Int, Float64, String, Int), it)...),

  # SMART_COMPONENTS
  82 => (it, w, ver) -> InteractiveBrokers.forward(w, :smartComponents(slurp((Int, VSmartComponent), it)...)),

  # NEWS_ARTICLE
  83 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :newsArticle, slurp((Int, Int, String), it)...),

  # TICK_NEWS
  84 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    args = slurp((Int, Int, String, String, String, String), it)

    InteractiveBrokers.forward(w, :tickNews, args...)
  end,

  # NEWS_PROVIDERS
  85 => (it, w, ver) -> InteractiveBrokers.forward(w, :newsProviders, convert(VNewsProvider, it)),

  # HISTORICAL_NEWS
  86 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :historicalNews, slurp((Int, String, String, String, String), it)...),

  # HISTORICAL_NEWS_END
  87 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :historicalNewsEnd, slurp((Int, Bool), it)...),

  # HEAD_TIMESTAMP
  88 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :headTimestamp, slurp((Int, String), it)...),

  # HISTOGRAM_DATA
  89 => (it, w, ver) -> InteractiveBrokers.forward(w, histogramData(slurp((Int, VHistogramEntry), it)...)),

  # HISTORICAL_DATA_UPDATE
  90 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int,
    count::Int,
    time::String,
    open::Float64,
    close::Float64,
    high::Float64,
    low::Float64,
    wap::Float64,
    volume::Float64 = it

    InteractiveBrokers.forward(w, :historicalDataUpdate, reqId, (; time, open, high, low, close,
      volume, wap, count))
  end,

  # REROUTE_MKT_DATA_REQ
  91 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :rerouteMktDataReq, slurp((Int, Int, String), it)...),

  # REROUTE_MKT_DEPTH_REQ
  92 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :rerouteMktDepthReq, slurp((Int, Int, String), it)...),

  # MARKET_RULE
  93 => (it, w, ver) -> InteractiveBrokers.forward(w, :marketRule, slurp((Int, VPriceIncrement), it)...),

  # PNL
  94 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int,
    dailyPnL::Float64,
    unrealizedPnL::Float64,
    realizedPnL::Float64 = it

    InteractiveBrokers.forward(w, :pnl, reqId, dailyPnL, unrealizedPnL, realizedPnL)
  end,

  # PNL_SINGLE
  95 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int,
    pos::Int,
    dailyPnL::Float64,
    unrealizedPnL::Union{Float64,Nothing},
    realizedPnL::Union{Float64,Nothing},
    value::Float64 = it

    InteractiveBrokers.forward(w, :pnlSingle, reqId, pos, dailyPnL, unrealizedPnL, realizedPnL, value)
  end,

  # HISTORICAL_TICKS
  96 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int,
    ticks::Vector{@NamedTuple{time::Int, ignore::Int, price::Float64, size::Float64}},
    done::Bool = it


    InteractiveBrokers.forward(w, :historicalTicks, reqId, HistoricalTick.(ticks), done)
  end,

  # HISTORICAL_TICKS_BID_ASK
  97 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int,
    ticks::VHistoricalTickBidAsk,
    done::Bool = it

    InteractiveBrokers.forward(w, :historicalTicksBidAsk, reqId, ticks, done)
  end,

  # HISTORICAL_TICKS_LAST
  98 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int,
    ticks::VHistoricalTickLast,
    done::Bool = it

    InteractiveBrokers.forward(w, :historicalTicksLast, reqId, ticks, done)
  end,

  # TICK_BY_TICK
  99 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int,
    ticktype::Int,
    time::Int = it

    if ticktype ∈ (1, 2)

      price::Float64,
      size::Float64,
      mask1::TickAttribLast,
      exchange::String,
      specialConditions::String = it

      InteractiveBrokers.forward(w, :tickByTickAllLast, reqId, ticktype, time, price, size, mask1, exchange, specialConditions)

    elseif ticktype == 3

      bidPrice::Float64,
      askPrice::Float64,
      bidSize::Float64,
      askSize::Float64,
      mask2::TickAttribBidAsk = it

      InteractiveBrokers.forward(w, :tickByTickBidAsk, reqId, time, bidPrice, askPrice, bidSize, askSize, mask2)

    elseif ticktype == 4

      InteractiveBrokers.forward(w, :tickByTickMidPoint, reqId, time, convert(Float64, it))

    else
      @warn "TICK_BY_TICK: unknown ticktype" T = ticktype
    end
  end,

  # ORDER_BOUND
  100 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :orderBound, collect(Int, take(it, 3))...),

  # COMPLETED_ORDER
  101 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    c = Contract()
    o = Order()
    os = OrderState()


    slurp!(c, [1:8; 10:12], it)

    slurp!(o, 4:9, it) # :action -> :tif

    slurp!(o, (:ocaGroup,
        :account,
        :openClose,
        :origin,
        :orderRef,
        :permId,
        :outsideRth,
        :hidden,
        :discretionaryAmt,
        :goodAfterTime,
        :faGroup,
        :faMethod,
        :faPercentage,
        :modelCode,
        :goodTillDate,
        :rule80A,
        :percentOffset,
        :settlingFirm,
        :shortSaleSlot,
        :designatedLocation,
        :exemptCode), it)

    slurp!(o, 43:47, it) # :startingPrice -> :stockRangeUpper

    slurp!(o, (:displaySize,
        :sweepToFill,
        :allOrNone,
        :minQty,
        :ocaType,
        :triggerMethod), it)

    slurp!(o, 50:53, it) # :volatility -> :deltaNeutralAuxPrice

    !isempty(o.deltaNeutralOrderType) && slurp!(o, [54; 59:61], it) # :deltaNeutralConId -> :deltaNeutralDesignatedLocation

    slurp!(o, (:continuousUpdate,
        :referencePriceType,
        :trailStopPrice,
        :trailingPercent), it)

    c.comboLegsDescrip,
    c.comboLegs = it

    slurp!(o, (:orderComboLegs,
        :smartComboRoutingParams,
        :scaleInitLevelSize,
        :scaleSubsLevelSize,
        :scalePriceIncrement), it)

    !isnothing(o.scalePriceIncrement) &&
      o.scalePriceIncrement > 0 && slurp!(o, 69:75, it) # :scalePriceAdjustValue -> :scaleRandomPercent

    o.hedgeType = it

    !isempty(o.hedgeType) && (o.hedgeParam = it)

    slurp!(o, (:clearingAccount,
        :clearingIntent,
        :notHeld), it)

    # DeltaNeutralContract
    convert(Bool, it) && (c.deltaNeutralContract = it)

    # AlgoStrategy
    o.algoStrategy = it

    !isempty(o.algoStrategy) && (o.algoParams = it)

    o.solicited,
    os.status,
    o.randomizeSize,
    o.randomizePrice = it

    o.orderType == "PEG BENCH" && slurp!(o, (:referenceContractId,
        :isPeggedChangeAmountDecrease,
        :peggedChangeAmount,
        :referenceChangeAmount,
        :referenceExchangeId), it)

    # Conditions
    o.conditions = it

    if !isempty(o.conditions)
      o.conditionsIgnoreRth,
      o.conditionsCancelOrder = it
    end

    slurp!(o, (:trailStopPrice,
        :lmtPriceOffset,
        :cashQty,
        :dontUseAutoPriceForHedge,
        :isOmsContainer), it)

    slurp!(o, 118:125, it) # :autoCancelDate -> :parentPermId

    os.completedTime,
    os.completedStatus = it

    slurp!(o, (:minTradeQty,
        :minCompeteSize,
        :competeAgainstBestOffset,
        :midOffsetAtWhole,
        :midOffsetAtHalf,
        :customerAccount,
        :professionalCustomer), it)

    InteractiveBrokers.forward(w, :completedOrder, c, o, os)
  end,

  # COMPLETED_ORDERS_END
  102 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :completedOrdersEnd),

  # REPLACE_FA_END
  103 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :replaceFAEnd, slurp((Int, String), it)...),

  # WSH_META_DATA
  104 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :wshMetaData, slurp((Int, String), it)...),

  # WSH_EVENT_DATA
  105 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :wshEventData, slurp((Int, String), it)...),

  # HISTORICAL_SCHEDULE
  106 => function (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict)

    reqId::Int,
    startDateTime::String,
    endDateTime::String,
    timeZone::String,
    sessions::VHistoricalSession = it

    InteractiveBrokers.forward(w, :historicalSchedule, reqId, startDateTime, endDateTime, timeZone, sessions)
  end,

  # USER_INFO
  107 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :userInfo, slurp((Int, String), it)...),

  # HISTORICAL_DATA_END
  108 => (it, w::InteractiveBrokers.AbstractIBCallbackWrapper, ver, Tab=Dict) -> InteractiveBrokers.forward(w, :historicalDataEnd, slurp((Int, String, String), it)...),

  # CURRENT_TIME_IN_MILLIS
  109 => (it, w, ver) -> InteractiveBrokers.forward(w, :currentTimeInMillis, convert(Int, it))
)
