module Requests

using ..Client

import ..AbstractCondition,
       ..Connection,
       ..Contract,
       ..ExecutionFilter,
       ..FaDataType,
       ..MarketDataType,
       ..Order,
       ..ScannerSubscription

include("encoder.jl")


# Initialize an Encoder()
enc() = Encoder(Client.buffer(false))

# Splat fields
splat(x, idx=fieldnames(typeof(x))) = (getfield(x, i) for i ∈ idx)

# Send messasge
function sendmsg(ib, e)

  Client.write_one(ib.socket, e.buf)

  nothing
end

# Handle requests that don't require special processing
function req_simple(ib, args...)

  o = enc()

  o(args...)

  sendmsg(ib, o)
end

#
# Requests
#
function reqMktData(ib::Connection, tickerId::Int, contract::Contract, genericTicks::String, snapshot::Bool, regulatorySnaphsot::Bool=false, mktDataOptions::NamedTuple=NamedTuple())

  o = enc()

  o(1, 11, ### REQ_MKT_DATA
    tickerId,
    splat(contract, 1:12))

  if contract.secType == "BAG"

    o(length(contract.comboLegs))

    for leg ∈ contract.comboLegs
      o(splat(leg, 1:4))
    end
  end

  isnothing(contract.deltaNeutralContract) ? o(false) :
                                             o(true, splat(contract.deltaNeutralContract))

  o(genericTicks,
    snapshot,
    regulatorySnaphsot,
    mktDataOptions)

  sendmsg(ib, o)
end

cancelMktData(ib::Connection, tickerId::Int) = req_simple(ib, 2, 2, tickerId) ### CANCEL_MKT_DATA

function placeOrder(ib::Connection, id::Int, contract::Contract, order::Order)

  o = enc()

  o(3) ### PLACE_ORDER

  ib.version < Client.ORDER_CONTAINER && o(45)

  o(id,
    splat(contract, [1:12; 14; 15]),
    splat(order, [4:9; 12; 83; 36; 37; 14:22]))  # "action" -> "tif"
                                                 # "ocaGroup" "account" "openClose" "origin"
                                                 # "orderRef" -> "hidden"

  if contract.secType == "BAG"

    # Contract.comboLegs
    o(length(contract.comboLegs))

    for leg ∈ contract.comboLegs
      o(splat(leg))
    end

    # Order.orderComboLegs
    o(length(order.orderComboLegs), order.orderComboLegs...)

    # Order.smartComboRoutingParams
    o(length(order.smartComboRoutingParams))

    for (n, v) ∈ pairs(order.smartComboRoutingParams)
      o(n, v)
    end
  end

  o(nothing,
    splat(order, (:discretionaryAmt,
                  :goodAfterTime,
                  :goodTillDate,
                  :faGroup,
                  :faMethod,
                  :faPercentage,
                  :faProfile,
                  :modelCode,
                  :shortSaleSlot,
                  :designatedLocation,
                  :exemptCode,
                  :ocaType,
                  :rule80A,
                  :settlingFirm,
                  :allOrNone,
                  :minQty,
                  :percentOffset,
                  :eTradeOnly,
                  :firmQuoteOnly,
                  :nbboPriceCap,
                  :auctionStrategy,
                  :startingPrice,
                  :stockRefPrice,
                  :delta,
                  :stockRangeLower,
                  :stockRangeUpper,
                  :overridePercentageConstraints,
                  :volatility,
                  :volatilityType,
                  :deltaNeutralOrderType,
                  :deltaNeutralAuxPrice)))

  !isempty(order.deltaNeutralOrderType) && o(splat(order, 56:65))

  o(splat(order, (:continuousUpdate,
                  :referencePriceType,
                  :trailStopPrice,
                  :trailingPercent,
                  :scaleInitLevelSize,
                  :scaleSubsLevelSize,
                  :scalePriceIncrement)))

  !isnothing(order.scalePriceIncrement) &&
  order.scalePriceIncrement > 0.0       && o(splat(order, 73:79))

  o(splat(order, (:scaleTable,
                  :activeStartTime,
                  :activeStopTime,
                  :hedgeType)))

  !isempty(order.hedgeType) && o(order.hedgeParam)

  o(splat(order, (:optOutSmartRouting,
                  :clearingAccount,
                  :clearingIntent,
                  :notHeld)))

  # DeltaNeutralContract
  isnothing(contract.deltaNeutralContract) ? o(false) :
                                             o(true, splat(contract.deltaNeutralContract))

  # Algo
  o(order.algoStrategy)

  if !isempty(order.algoStrategy)

    o(length(order.algoParams))

    for (n, v) ∈ pairs(order.algoParams)
      o(n, v)
    end
  end

  o(splat(order, (:algoId,
                  :whatIf,
                  :orderMiscOptions,
                  :solicited,
                  :randomizeSize,
                  :randomizePrice)))

  if order.orderType == "PEG BENCH"
    o(splat(order, (:referenceContractId,
                    :isPeggedChangeAmountDecrease,
                    :peggedChangeAmount,
                    :referenceChangeAmount,
                    :referenceExchangeId)))
  end

  # Conditions
  o(length(order.conditions))

  if !isempty(order.conditions)

    for c ∈ order.conditions
      o(c)
    end

    o(order.conditionsIgnoreRth,
      order.conditionsCancelOrder)
  end

  o(splat(order, (:adjustedOrderType,
                  :triggerPrice,
                  :lmtPriceOffset,
                  :adjustedStopPrice,
                  :adjustedStopLimitPrice,
                  :adjustedTrailingAmount,
                  :adjustableTrailingUnit,
                  :extOperator)))

  o(order.softDollarTier.name,
    order.softDollarTier.val)

  o(splat(order, (:cashQty,
                  :mifid2DecisionMaker,
                  :mifid2DecisionAlgo,
                  :mifid2ExecutionTrader,
                  :mifid2ExecutionAlgo,
                  :dontUseAutoPriceForHedge)))

  ib.version ≥ Client.ORDER_CONTAINER && o(order.isOmsContainer)

  ib.version ≥ Client.D_PEG_ORDERS && o(order.discretionaryUpToLimitPrice)

  ib.version ≥ Client.PRICE_MGMT_ALGO && o(order.usePriceMgmtAlgo)

  sendmsg(ib, o)
end

cancelOrder(ib::Connection, id::Int) = req_simple(ib, 4, 1, id) ### CANCEL_ORDER

reqOpenOrders(ib::Connection) = req_simple(ib, 5, 1) ### REQ_OPEN_ORDERS

reqAccountUpdates(ib::Connection, subscribe::Bool, acctCode::String) = req_simple(ib, 6, 2, subscribe, acctCode) ### REQ_ACCT_DATA

function reqExecutions(ib::Connection, reqId::Int, filter::ExecutionFilter)

  o = enc()

  o(7, 3) ### REQ_EXECUTIONS

  o(reqId, splat(filter))

  sendmsg(ib, o)
end

reqIds(ib::Connection) = req_simple(ib, 8, 1, 1) ### REQ_IDS
                                           #  ^ Hardcoded numIds=1. It's deprecated and unused

function reqContractDetails(ib::Connection, reqId::Int, contract::Contract)

  o = enc()

  o(9, 8,   ### REQ_CONTRACT_DATA
    reqId,
    splat(contract, 1:15))

  sendmsg(ib, o)
end

function reqMktDepth(ib::Connection, tickerId::Int, contract::Contract, numRows::Int, isSmartDepth::Bool, mktDepthOptions::NamedTuple=NamedTuple())

  o = enc()

  o(10, 5,      ### REQ_MKT_DEPTH
    tickerId,
    splat(contract,
          ib.version ≥ Client.MKT_DEPTH_PRIM_EXCHANGE ? (1:12) : [1:8; 10:12]),
    numRows)

  ib.version ≥ Client.SMART_DEPTH && o(isSmartDepth)

  o(mktDepthOptions)

  sendmsg(ib, o)
end

function cancelMktDepth(ib::Connection, tickerId::Int, isSmartDepth::Bool)

  o = enc()

  o(11, 1,   ### CANCEL_MKT_DEPTH
    tickerId)

  ib.version ≥ Client.SMART_DEPTH && o(isSmartDepth)

  sendmsg(ib, o)
end

reqNewsBulletins(ib::Connection, allMsgs::Bool) = req_simple(ib, 12, 1, allMsgs) ### REQ_NEWS_BULLETINS

cancelNewsBulletins(ib::Connection) = req_simple(ib, 13, 1) ### CANCEL_NEWS_BULLETINS

setServerLogLevel(ib::Connection, logLevel::Int) = req_simple(ib, 14, 1, logLevel) ### SET_SERVER_LOGLEVEL

reqAutoOpenOrders(ib::Connection, bAutoBind::Bool) = req_simple(ib, 15, 1, bAutoBind) ### REQ_AUTO_OPEN_ORDERS

reqAllOpenOrders(ib::Connection) = req_simple(ib, 16, 1) ### REQ_ALL_OPEN_ORDERS

reqManagedAccts(ib::Connection) = req_simple(ib, 17, 1)  ### REQ_MANAGED_ACCTS

function requestFA(ib::Connection, faDataType::FaDataType)

  o = enc()

  o(18, 1,   ### REQ_FA
    Int(faDataType))

  sendmsg(ib, o)
end

function replaceFA(ib::Connection, reqId::Int, faDataType::FaDataType, xml::String)

  o = enc()

  o(19, 1,    ### REPLACE_FA
    Int(faDataType),
    xml)

  ib.version ≥ Client.REPLACE_FA_END && o(reqId)

  sendmsg(ib, o)
end

function reqHistoricalData(ib::Connection, tickerId::Int, contract::Contract, endDateTime::String, durationStr::String, barSizeSetting::String, whatToShow::String, useRTH::Bool, formatDate::Int, keepUpToDate::Bool, chartOptions::NamedTuple=NamedTuple())

  o = enc()

  o(20,   ### REQ_HISTORICAL_DATA
    tickerId,
    splat(contract, 1:13),
    endDateTime,
    barSizeSetting,
    durationStr,
    useRTH,
    whatToShow,
    formatDate)

  if contract.secType == "BAG"

    o(length(contract.comboLegs))

    for leg ∈ contract.comboLegs
      o(splat(leg, 1:4))
    end
  end

  o(keepUpToDate,
    chartOptions)

  sendmsg(ib, o)
end

function exerciseOptions(ib::Connection, tickerId::Int, contract::Contract, exerciseAction::Int, exerciseQuantity::Int, account::String, override::Int)

  o = enc()

  o(21, 2,    ### EXERCISE_OPTIONS
    tickerId,
    splat(contract, [1:8; 10:12]),
    exerciseAction,
    exerciseQuantity,
    account,
    override)

  sendmsg(ib, o)
end

function reqScannerSubscription(ib::Connection, tickerId::Int, subscription::ScannerSubscription, scannerSubscriptionOptions::NamedTuple=NamedTuple(), scannerSubscriptionFilterOptions::NamedTuple=NamedTuple())

  o = enc()

  o(22)    ### REQ_SCANNER_SUBSCRIPTION

  ib.version < Client.SCANNER_GENERIC_OPTS && o(4)

  o(tickerId,
    splat(subscription))

  ib.version ≥ Client.SCANNER_GENERIC_OPTS && o(scannerSubscriptionFilterOptions)

  o(scannerSubscriptionOptions)

  sendmsg(ib, o)
end

cancelScannerSubscription(ib::Connection, tickerId::Int) = req_simple(ib, 23, 1, tickerId) ### CANCEL_SCANNER_SUBSCRIPTION

reqScannerParameters(ib::Connection) = req_simple(ib, 24, 1) ### REQ_SCANNER_PARAMETERS

cancelHistoricalData(ib::Connection, tickerId::Int) =  req_simple(ib, 25, 1, tickerId) ### CANCEL_HISTORICAL_DATA

reqCurrentTime(ib::Connection) = req_simple(ib, 49, 1) ### REQ_CURRENT_TIME

function reqRealTimeBars(ib::Connection, tickerId::Int, contract::Contract, barSize::Int, whatToShow::String, useRTH::Bool, realTimeBarsOptions::NamedTuple=NamedTuple())

  o = enc()

  o(50, 3,      ### REQ_REAL_TIME_BARS
    tickerId,
    splat(contract, 1:12),
    barSize,
    whatToShow,
    useRTH,
    realTimeBarsOptions)

  sendmsg(ib, o)
end

cancelRealTimeBars(ib::Connection, tickerId::Int) = req_simple(ib, 51, 1, tickerId) ### CANCEL_REAL_TIME_BARS

function reqFundamentalData(ib::Connection, reqId::Int, contract::Contract, reportType::String, fundamentalDataOptions::NamedTuple=NamedTuple())

  o = enc()

  o(52, 2,     ### REQ_FUNDAMENTAL_DATA
    reqId,
    splat(contract, [1:3; 8:11]),
    reportType,
    fundamentalDataOptions)

  sendmsg(ib, o)
end

cancelFundamentalData(ib::Connection, reqId::Int) = req_simple(ib, 53, 1, reqId) ### CANCEL_FUNDAMENTAL_DATA

function calculateImpliedVolatility(ib::Connection, reqId::Int, contract::Contract, optionPrice::Float64, underPrice::Float64, miscOptions::NamedTuple=NamedTuple())

  o = enc()

  o(54, 2,     ### REQ_CALC_IMPLIED_VOLAT
    reqId,
    splat(contract, 1:12),
    optionPrice,
    underPrice,
    miscOptions)

  sendmsg(ib, o)
end

function calculateOptionPrice(ib::Connection, reqId::Int, contract::Contract, volatility::Float64, underPrice::Float64, miscOptions::NamedTuple=NamedTuple())

  o = enc()

  o(55, 2,     ### REQ_CALC_OPTION_PRICE
    reqId,
    splat(contract, 1:12),
    volatility,
    underPrice,
    miscOptions)

  sendmsg(ib, o)
end

cancelCalculateImpliedVolatility(ib::Connection, reqId::Int) = req_simple(ib, 56, 1, reqId) ### CANCEL_CALC_IMPLIED_VOLAT

cancelCalculateOptionPrice(ib::Connection, reqId::Int) = req_simple(ib, 57, 1, reqId) ### CANCEL_CALC_OPTION_PRICE

reqGlobalCancel(ib::Connection) = req_simple(ib, 58, 1) ### REQ_GLOBAL_CANCEL

reqMarketDataType(ib::Connection, marketDataType::MarketDataType) = req_simple(ib, 59, 1, marketDataType) ### REQ_MARKET_DATA_TYPE

reqPositions(ib::Connection) = req_simple(ib, 61, 1) ### REQ_POSITIONS

reqAccountSummary(ib::Connection, reqId::Int, groupName::String, tags::String) = req_simple(ib, 62, 1, reqId, groupName, tags) ### REQ_ACCOUNT_SUMMARY

cancelAccountSummary(ib::Connection, reqId::Int) = req_simple(ib, 63, 1, reqId) ### CANCEL_ACCOUNT_SUMMARY

cancelPositions(ib::Connection) = req_simple(ib, 64, 1) ### CANCEL_POSITIONS

verifyRequest(ib::Connection, apiName::String, apiVersion::String) = req_simple(ib, 65, 1, apiName, apiVersion) ### VERIFY_REQUEST

verifyMessage(ib::Connection, apiData::String) = req_simple(ib, 66, 1, apiData) ### VERIFY_MESSAGE

queryDisplayGroups(ib::Connection, reqId::Int) = req_simple(ib, 67, 1, reqId) ### QUERY_DISPLAY_GROUPS

subscribeToGroupEvents(ib::Connection, reqId::Int, groupId::Int) = req_simple(ib, 68, 1, reqId, groupId) ### SUBSCRIBE_TO_GROUP_EVENTS

updateDisplayGroup(ib::Connection, reqId::Int, contractInfo::String) = req_simple(ib, 69, 1, reqId, contractInfo) ### UPDATE_DISPLAY_GROUP

unsubscribeFromGroupEvents(ib::Connection, reqId::Int) = req_simple(ib, 70, 1, reqId) ### UNSUBSCRIBE_FROM_GROUP_EVENTS

startApi(ib::Connection, clientId::Int, optionalCapabilities::String) = req_simple(ib, 71, 2, clientId, optionalCapabilities) ### START_API

verifyAndAuthRequest(ib::Connection, apiName::String, apiVersion::String, opaqueIsvKey::String) = req_simple(ib, 72, 1, apiName, apiVersion, opaqueIsvKey) ### VERIFY_AND_AUTH_REQUEST

verifyAndAuthMessage(ib::Connection, apiData::String, xyzResponse::String) = req_simple(ib, 73, 1, apiData, xyzResponse) ### VERIFY_AND_AUTH_MESSAGE

reqPositionsMulti(ib::Connection, reqId::Int, account::String, modelCode::String) = req_simple(ib, 74, 1, reqId, account, modelCode) ### REQ_POSITIONS_MULTI

cancelPositionsMulti(ib::Connection, reqId::Int) = req_simple(ib, 75, 1, reqId) ### CANCEL_POSITIONS_MULTI

reqAccountUpdatesMulti(ib::Connection, reqId::Int, account::String, modelCode::String, ledgerAndNLV::Bool) = req_simple(ib, 76, 1, reqId, account, modelCode, ledgerAndNLV) ### REQ_ACCOUNT_UPDATES_MULTI

cancelAccountUpdatesMulti(ib::Connection, reqId::Int) = req_simple(ib, 77, 1, reqId) ### CANCEL_ACCOUNT_UPDATES_MULTI

reqSecDefOptParams(ib::Connection, reqId::Int, underlyingSymbol::String, futFopExchange::String, underlyingSecType::String, underlyingConId::Int) = req_simple(ib, 78, reqId, underlyingSymbol, futFopExchange, underlyingSecType, underlyingConId) ### REQ_SEC_DEF_OPT_PARAMS

reqSoftDollarTiers(ib::Connection, reqId::Int) = req_simple(ib, 79, reqId) ### REQ_SOFT_DOLLAR_TIERS

reqFamilyCodes(ib::Connection) = req_simple(ib, 80) ### REQ_FAMILY_CODES

reqMatchingSymbols(ib::Connection, reqId::Int, pattern::String) = req_simple(ib, 81, reqId, pattern) ### REQ_MATCHING_SYMBOLS

reqMktDepthExchanges(ib::Connection) = req_simple(ib, 82) ### REQ_MKT_DEPTH_EXCHANGES

reqSmartComponents(ib::Connection, reqId::Int, bboExchange::String) = req_simple(ib, 83, reqId, bboExchange) ### REQ_SMART_COMPONENTS

function reqNewsArticle(ib::Connection, requestId::Int, providerCode::String, articleId::String, newsArticleOptions::NamedTuple=NamedTuple())

  o = enc()

  o(84,    ### REQ_NEWS_ARTICLE
    requestId,
    providerCode,
    articleId,
    newsArticleOptions)

  sendmsg(ib, o)
end

reqNewsProviders(ib::Connection) = req_simple(ib, 85) ### REQ_NEWS_PROVIDERS

function reqHistoricalNews(ib::Connection, requestId::Int, conId::Int, providerCodes::String, startDateTime::String, endDateTime::String, totalResults::Int, historicalNewsOptions::NamedTuple=NamedTuple())

  o = enc()

  o(86,      ### REQ_HISTORICAL_NEWS
    requestId,
    conId,
    providerCodes,
    startDateTime,
    endDateTime,
    totalResults,
    historicalNewsOptions)

  sendmsg(ib, o)
end

function reqHeadTimestamp(ib::Connection, tickerId::Int, contract::Contract, whatToShow::String, useRTH::Bool, formatDate::Int)

  o = enc()

  o(87,     ### REQ_HEAD_TIMESTAMP
    tickerId,
    splat(contract, 1:13),
    useRTH,
    whatToShow,
    formatDate)

  sendmsg(ib, o)
end

function reqHistogramData(ib::Connection, reqId::Int, contract::Contract, useRTH::Bool, timePeriod::String)

  o = enc()

  o(88,    ### REQ_HISTOGRAM_DATA
    reqId,
    splat(contract, 1:13),
    useRTH,
    timePeriod)

  sendmsg(ib, o)
end

cancelHistogramData(ib::Connection, reqId::Int) = req_simple(ib, 89, reqId) ### CANCEL_HISTOGRAM_DATA

cancelHeadTimestamp(ib::Connection, tickerId::Int) = req_simple(ib, 90, tickerId) ### CANCEL_HEAD_TIMESTAMP

reqMarketRule(ib::Connection, marketRuleId::Int) = req_simple(ib, 91, marketRuleId) ### REQ_MARKET_RULE

reqPnL(ib::Connection, reqId::Int, account::String, modelCode::String) = req_simple(ib, 92, reqId, account, modelCode) ### REQ_PNL

cancelPnL(ib::Connection, reqId::Int) = req_simple(ib, 93, reqId) ### CANCEL_PNL

reqPnLSingle(ib::Connection, reqId::Int, account::String, modelCode::String, conId::Int) = req_simple(ib, 94, reqId, account, modelCode, conId) ### REQ_PNL_SINGLE

cancelPnLSingle(ib::Connection, reqId::Int) = req_simple(ib, 95, reqId) ### CANCEL_PNL_SINGLE

function reqHistoricalTicks(ib::Connection, reqId::Int, contract::Contract, startDateTime::String, endDateTime::String, numberOfTicks::Int, whatToShow::String, useRTH::Bool, ignoreSize::Bool, miscOptions::NamedTuple=NamedTuple())

  o = enc()

  o(96,      ### REQ_HISTORICAL_TICKS
    reqId,
    splat(contract, 1:13),
    startDateTime,
    endDateTime,
    numberOfTicks,
    whatToShow,
    useRTH,
    ignoreSize,
    miscOptions)

  sendmsg(ib, o)
end

function reqTickByTickData(ib::Connection, reqId::Int, contract::Contract, tickType::String, numberOfTicks::Int, ignoreSize::Bool)

  o = enc()

  o(97,      ### REQ_TICK_BY_TICK_DATA
    reqId,
    splat(contract, 1:12),
    tickType,
    numberOfTicks,
    ignoreSize)

  sendmsg(ib, o)
end

cancelTickByTickData(ib::Connection, reqId::Int) = req_simple(ib, 98, reqId) ### CANCEL_TICK_BY_TICK_DATA

reqCompletedOrders(ib::Connection, apiOnly::Bool) = req_simple(ib, 99, apiOnly) ### REQ_COMPLETED_ORDERS


# Exports
export reqMktData,
       cancelMktData,
       placeOrder,
       cancelOrder,
       reqOpenOrders,
       reqAccountUpdates,
       reqExecutions,
       reqIds,
       reqContractDetails,
       reqMktDepth,
       cancelMktDepth,
       reqNewsBulletins,
       cancelNewsBulletins,
       setServerLogLevel,
       reqAutoOpenOrders,
       reqAllOpenOrders,
       reqManagedAccts,
       requestFA,
       replaceFA,
       reqHistoricalData,
       exerciseOptions,
       reqScannerSubscription,
       cancelScannerSubscription,
       reqScannerParameters,
       cancelHistoricalData,
       reqCurrentTime,
       reqRealTimeBars,
       cancelRealTimeBars,
       reqFundamentalData,
       cancelFundamentalData,
       calculateImpliedVolatility,
       calculateOptionPrice,
       cancelCalculateImpliedVolatility,
       cancelCalculateOptionPrice,
       reqGlobalCancel,
       reqMarketDataType,
       reqPositions,
       reqAccountSummary,
       cancelAccountSummary,
       cancelPositions,
       verifyRequest,
       verifyMessage,
       queryDisplayGroups,
       subscribeToGroupEvents,
       updateDisplayGroup,
       unsubscribeFromGroupEvents,
#       startApi,
       verifyAndAuthRequest,
       verifyAndAuthMessage,
       reqPositionsMulti,
       cancelPositionsMulti,
       reqAccountUpdatesMulti,
       cancelAccountUpdatesMulti,
       reqSecDefOptParams,
       reqSoftDollarTiers,
       reqFamilyCodes,
       reqMatchingSymbols,
       reqMktDepthExchanges,
       reqSmartComponents,
       reqNewsArticle,
       reqNewsProviders,
       reqHistoricalNews,
       reqHeadTimestamp,
       reqHistogramData,
       cancelHistogramData,
       cancelHeadTimestamp,
       reqMarketRule,
       reqPnL,
       cancelPnL,
       reqPnLSingle,
       cancelPnLSingle,
       reqHistoricalTicks,
       reqTickByTickData,
       cancelTickByTickData,
       reqCompletedOrders
end
