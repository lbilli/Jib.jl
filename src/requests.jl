module Requests

using ..Client

import ..AbstractCondition,
       ..Connection,
       ..Contract,
       ..ExecutionFilter,
       ..FaDataType,
       ..MarketDataType,
       ..Order,
       ..OrderCancel,
       ..ScannerSubscription,
       ..WshEventData,
       ..PB,
       ..maptopb


function sendmsg(ib, msgid::Int, msg::Union{PB.Message,Nothing}=nothing)

  buf = Client.buffer(false)

  write(buf, hton(Client.RAWIDTYPE(msgid + Client.PROTOBUF_MSG_ID)))

  isnothing(msg) || PB.serialize(buf, msg)

  Client.write_one(ib.socket, buf)

  nothing
end

# Handle requests that don't require special processing
req_simple(ib, msgid, value::Int) = sendmsg(ib, msgid, PB.Message(:SingleInt32; value))

req_simple(ib, msgid, value::Bool) = sendmsg(ib, msgid, maptopb(:SingleBool; value))

req_simple(ib, msgid, reqId::Int, data::String) = sendmsg(ib, msgid, maptopb(:StringData; reqId, data))

#
# Requests
#
reqMktData(ib::Connection, reqId::Int, contract::Contract, genericTicks::String, snapshot::Bool,
           regulatorySnapshot::Bool=false, mktDataOptions::NamedTuple=(;)) =
  sendmsg(ib, 1, ### REQ_MKT_DATA
          maptopb(:MarketDataRequest; reqId,
                                      contract,
                                      genericTicks,
                                      snapshot,
                                      regulatorySnapshot,
                                      mktDataOptions))

cancelMktData(ib::Connection, reqId::Int) = req_simple(ib, 2, reqId) ### CANCEL_MKT_DATA

function placeOrder(ib::Connection, id::Int, contract::Contract, order::Order)

  msgid = 3 ### PLACE_ORDER

  c = maptopb(contract, (:lastTradeDate,))

  n = length(order.orderComboLegs)

  @assert n ∈ (0, length(contract.comboLegs))

  if n > 0
    for (p, cl) ∈ zip(order.orderComboLegs, c[:comboLegs])
      cl[:perLegPrice] = p
    end
  end

  o = maptopb(order, (:orderId,
                      :rule80A,
                      :auctionStrategy,
                      :basisPoints,
                      :basisPointsType,
                      :orderComboLegs,
                      :mifid2DecisionMaker,
                      :mifid2DecisionAlgo,
                      :mifid2ExecutionTrader,
                      :mifid2ExecutionAlgo,
                      :autoCancelDate,
                      :filledQuantity,
                      :refFuturesConId,
                      :shareholder,
                      :parentPermId,

                      # Require separate handling
                      :totalQuantity,         # Decimal
                      :routeMarketableToBbo,  # Three-state boolean
                      :usePriceMgmtAlgo,      # Three-state boolean
                      :seekPriceImprovement)) # Three-state boolean

  o[:totalQuantity] = string(order.totalQuantity)

  for n ∈ (:routeMarketableToBbo, :usePriceMgmtAlgo, :seekPriceImprovement)
    val = getfield(order, n)

    isnothing(val) || (o[n] = Int(val))
  end

  if ib.version < Client.ADDITIONAL_ORDER_PARAMS_1
    for n ∈ (:deactivate, :postOnly, :allowPreOpen, :ignoreOpenAuction)
      PB.has(o, n) && error("Order parameter :$n not supported")
    end

  end

  if ib.version < Client.ADDITIONAL_ORDER_PARAMS_2
    for n ∈ (:routeMarketableToBbo, :seekPriceImprovement, :whatIfType)
      PB.has(o, n) && error("Order parameter :$n not supported")
    end
  end

  msg = PB.Message(:PlaceOrderRequest; orderId=id,
                                       contract=c,
                                       order=o)

  sendmsg(ib, msgid, msg)
end

cancelOrder(ib::Connection, id::Int, orderCancel::OrderCancel) =
  sendmsg(ib, 4, ### CANCEL_ORDER
          maptopb(:CancelOrderRequest; orderId=id,
                                       orderCancel))

reqOpenOrders(ib::Connection) = sendmsg(ib, 5) ### REQ_OPEN_ORDERS

reqAccountUpdates(ib::Connection, subscribe::Bool, acctCode::String) =
  sendmsg(ib, 6, ### REQ_ACCT_DATA
          maptopb(:AccountDataRequest; subscribe, acctCode))

reqExecutions(ib::Connection, reqId::Int, filter::ExecutionFilter) =
  sendmsg(ib, 7, ### REQ_EXECUTIONS
          maptopb(:ExecutionRequest; reqId, filter))

reqIds(ib::Connection) =
  # numIds is omitted as it's deprecated and unused
  sendmsg(ib, 8) ### REQ_IDS


reqContractDetails(ib::Connection, reqId::Int, contract::Contract) =
  sendmsg(ib, 9, ### REQ_CONTRACT_DATA
          maptopb(:ContractDataRequest; reqId, contract))

reqMktDepth(ib::Connection, reqId::Int, contract::Contract, numRows::Int,
            isSmartDepth::Bool, mktDepthOptions::NamedTuple=(;)) =
  sendmsg(ib, 10, ### REQ_MKT_DEPTH
          maptopb(:MarketDepthRequest; reqId,
                                       contract,
                                       numRows,
                                       isSmartDepth,
                                       mktDepthOptions))

cancelMktDepth(ib::Connection, reqId::Int, isSmartDepth::Bool) =
  sendmsg(ib, 11, ### CANCEL_MKT_DEPTH
          maptopb(:CancelMarketDepth; reqId, isSmartDepth))

reqNewsBulletins(ib::Connection, allMsgs::Bool) = req_simple(ib, 12, allMsgs) ### REQ_NEWS_BULLETINS

cancelNewsBulletins(ib::Connection) = sendmsg(ib, 13) ### CANCEL_NEWS_BULLETINS

setServerLogLevel(ib::Connection, logLevel::Int) = req_simple(ib, 14, logLevel) ### SET_SERVER_LOGLEVEL

reqAutoOpenOrders(ib::Connection, bAutoBind::Bool) = req_simple(ib, 15, bAutoBind) ### REQ_AUTO_OPEN_ORDER

reqAllOpenOrders(ib::Connection) = sendmsg(ib, 16) ### REQ_ALL_OPEN_ORDERS

reqManagedAccts(ib::Connection) = sendmsg(ib, 17) ### REQ_MANAGED_ACCTS

requestFA(ib::Connection, faDataType::FaDataType) = req_simple(ib, 18, Int(faDataType)) ### REQ_FA

replaceFA(ib::Connection, reqId::Int, faDataType::FaDataType, xml::String) =
  sendmsg(ib, 19, ### REPLACE_FA
          maptopb(:FAReplace; reqId,
                              faDataType=Int(faDataType),
                              xml))

reqHistoricalData(ib::Connection, reqId::Int, contract::Contract, endDateTime::String,
                  duration::String, barSizeSetting::String, whatToShow::String, useRTH::Bool,
                  formatDate::Int, keepUpToDate::Bool, chartOptions::NamedTuple=(;)) =
  sendmsg(ib, 20, ### REQ_HISTORICAL_DATA
          maptopb(:HistoricalDataRequest; reqId,
                                          contract,
                                          endDateTime,
                                          duration,
                                          barSizeSetting,
                                          whatToShow,
                                          useRTH,
                                          formatDate,
                                          keepUpToDate,
                                          chartOptions))

exerciseOptions(ib::Connection, reqId::Int, contract::Contract, exerciseAction::Int,
                         exerciseQuantity::Int, account::String, override::Int, manualOrderTime::String,
                         customerAccount::String, professionalCustomer::Bool) =
  sendmsg(ib, 21, ### EXERCISE_OPTIONS
          maptopb(:ExerciseOptionsRequest; reqId,
                                           contract,
                                           exerciseAction,
                                           exerciseQuantity,
                                           account,
                                           override,
                                           manualOrderTime,
                                           customerAccount,
                                           professionalCustomer))

function reqScannerSubscription(ib::Connection, reqId::Int, subscription::ScannerSubscription,
                                scannerSubscriptionOptions::NamedTuple=(;), scannerSubscriptionFilterOptions::NamedTuple=(;))

  msgid = 22 ### REQ_SCANNER_SUBSCRIPTION

  sub = maptopb(subscription)

  isempty(scannerSubscriptionOptions) ||
    (sub[:scannerSubscriptionOptions] = maptopb(scannerSubscriptionOptions))

  isempty(scannerSubscriptionFilterOptions) ||
    (sub[:scannerSubscriptionFilterOptions] = maptopb(scannerSubscriptionFilterOptions))

  sendmsg(ib, msgid, PB.Message(:ScannerSubscriptionRequest; reqId,
                                                             subscription=sub))
end

cancelScannerSubscription(ib::Connection, reqId::Int) = req_simple(ib, 23, reqId) ### CANCEL_SCANNER_SUBSCRIPTION

reqScannerParameters(ib::Connection) = sendmsg(ib, 24) ### REQ_SCANNER_PARAMETERS

cancelHistoricalData(ib::Connection, reqId::Int) =  req_simple(ib, 25, reqId) ### CANCEL_HISTORICAL_DATA

reqCurrentTime(ib::Connection) = sendmsg(ib, 49) ### REQ_CURRENT_TIME

reqRealTimeBars(ib::Connection, reqId::Int, contract::Contract, barSize::Int,
                whatToShow::String, useRTH::Bool, realTimeBarsOptions::NamedTuple=(;)) =
  sendmsg(ib, 50, ### REQ_REAL_TIME_BARS
          maptopb(:RealTimeBarsRequest; reqId,
                                        contract,
                                        barSize,
                                        whatToShow,
                                        useRTH,
                                        realTimeBarsOptions))

cancelRealTimeBars(ib::Connection, reqId::Int) = req_simple(ib, 51, reqId) ### CANCEL_REAL_TIME_BARS

reqFundamentalData(ib::Connection, reqId::Int, contract::Contract, reportType::String, fundamentalDataOptions::NamedTuple=(;)) =
  sendmsg(ib, 52, ### REQ_FUNDAMENTAL_DATA
          maptopb(:FundamentalDataRequest; reqId,
                                           contract,
                                           reportType,
                                           fundamentalDataOptions))

cancelFundamentalData(ib::Connection, reqId::Int) = req_simple(ib, 53, reqId) ### CANCEL_FUNDAMENTAL_DATA

calculateImpliedVolatility(ib::Connection, reqId::Int, contract::Contract, optionPrice::Float64, underPrice::Float64, miscOptions::NamedTuple=(;)) =
  sendmsg(ib, 54, ### REQ_CALC_IMPLIED_VOLAT
          maptopb(:CalculateImpliedVolatilityRequest; reqId,
                                                      contract,
                                                      optionPrice,
                                                      underPrice,
                                                      miscOptions))

calculateOptionPrice(ib::Connection, reqId::Int, contract::Contract, volatility::Float64, underPrice::Float64, miscOptions::NamedTuple=(;)) =
  sendmsg(ib, 55, ### REQ_CALC_OPTION_PRICE
          maptopb(:CalculateOptionPriceRequest; reqId,
                                                contract,
                                                volatility,
                                                underPrice,
                                                miscOptions))

cancelCalculateImpliedVolatility(ib::Connection, reqId::Int) = req_simple(ib, 56, reqId) ### CANCEL_CALC_IMPLIED_VOLAT

cancelCalculateOptionPrice(ib::Connection, reqId::Int) = req_simple(ib, 57, reqId) ### CANCEL_CALC_OPTION_PRICE

reqGlobalCancel(ib::Connection, orderCancel::OrderCancel) =
  sendmsg(ib, 58, ### REQ_GLOBAL_CANCEL
          maptopb(:GlobalCancelRequest; orderCancel))

reqMarketDataType(ib::Connection, marketDataType::MarketDataType) = req_simple(ib, 59, Int(marketDataType)) ### REQ_MARKET_DATA_TYPE

reqPositions(ib::Connection) = sendmsg(ib, 61) ### REQ_POSITIONS

reqAccountSummary(ib::Connection, reqId::Int, group::String, tags::String) =
  sendmsg(ib, 62, ### REQ_ACCOUNT_SUMMARY
          maptopb(:AccountSummaryRequest; reqId,
                                          group,
                                          tags))

cancelAccountSummary(ib::Connection, reqId::Int) = req_simple(ib, 63, reqId) ### CANCEL_ACCOUNT_SUMMARY

cancelPositions(ib::Connection) = sendmsg(ib, 64) ### CANCEL_POSITIONS

verifyRequest(ib::Connection, apiName::String, apiVersion::String) =
  sendmsg(ib, 65, ### VERIFY_REQUEST
          maptopb(:VerifyRequest; apiName, apiVersion))

verifyMessage(ib::Connection, apiData::String) =
  sendmsg(ib, 66, ### VERIFY_MESSAGE
          PB.Message(:SingleString; value=apiData))

queryDisplayGroups(ib::Connection, reqId::Int) = req_simple(ib, 67, reqId) ### QUERY_DISPLAY_GROUPS

subscribeToGroupEvents(ib::Connection, reqId::Int, groupId::Int) =
  sendmsg(ib, 68, ### SUBSCRIBE_TO_GROUP_EVENTS
          PB.Message(:SubscribeToGroupEventsRequest; reqId, groupId))

updateDisplayGroup(ib::Connection, reqId::Int, contractInfo::String) =
  req_simple(ib, 69, reqId, contractInfo) ### UPDATE_DISPLAY_GROUP

unsubscribeFromGroupEvents(ib::Connection, reqId::Int) = req_simple(ib, 70, reqId) ### UNSUBSCRIBE_FROM_GROUP_EVENTS

startApi(ib::Connection, clientId::Int, optionalCapabilities::String) = req_simple(ib, 71, clientId, optionalCapabilities) ### START_API

# verifyAndAuthRequest(ib::Connection, apiName::String, apiVersion::String, opaqueIsvKey::String) = req_simple(ib, 72, 1, apiName, apiVersion, opaqueIsvKey) ### VERIFY_AND_AUTH_REQUEST
#
# verifyAndAuthMessage(ib::Connection, apiData::String, xyzResponse::String) = req_simple(ib, 73, 1, apiData, xyzResponse) ### VERIFY_AND_AUTH_MESSAGE

reqPositionsMulti(ib::Connection, reqId::Int, account::String, modelCode::String) =
  sendmsg(ib, 74, ### REQ_POSITIONS_MULTI
          maptopb(:PositionsMultiRequest; reqId, account, modelCode))

cancelPositionsMulti(ib::Connection, reqId::Int) = req_simple(ib, 75, reqId) ### CANCEL_POSITIONS_MULTI

reqAccountUpdatesMulti(ib::Connection, reqId::Int, account::String, modelCode::String, ledgerAndNLV::Bool) =
  sendmsg(ib, 76, ### REQ_ACCOUNT_UPDATES_MULTI
          maptopb(:AccountUpdatesMultiRequest; reqId,
                                               account,
                                               modelCode,
                                               ledgerAndNLV))

cancelAccountUpdatesMulti(ib::Connection, reqId::Int) = req_simple(ib, 77, reqId) ### CANCEL_ACCOUNT_UPDATES_MULTI

reqSecDefOptParams(ib::Connection, reqId::Int, underlyingSymbol::String, futFopExchange::String, underlyingSecType::String, underlyingConId::Int) =
  sendmsg(ib, 78, ### REQ_SEC_DEF_OPT_PARAMS
          maptopb(:SecDefOptParamsRequest; reqId,
                                           underlyingSymbol,
                                           futFopExchange,
                                           underlyingSecType,
                                           underlyingConId))

reqSoftDollarTiers(ib::Connection, reqId::Int) = req_simple(ib, 79, reqId) ### REQ_SOFT_DOLLAR_TIERS

reqFamilyCodes(ib::Connection) = sendmsg(ib, 80) ### REQ_FAMILY_CODES

reqMatchingSymbols(ib::Connection, reqId::Int, pattern::String) = req_simple(ib, 81, reqId, pattern) ### REQ_MATCHING_SYMBOLS

reqMktDepthExchanges(ib::Connection) = sendmsg(ib, 82) ### REQ_MKT_DEPTH_EXCHANGES

reqSmartComponents(ib::Connection, reqId::Int, bboExchange::String) = req_simple(ib, 83, reqId, bboExchange) ### REQ_SMART_COMPONENTS

reqNewsArticle(ib::Connection, reqId::Int, providerCode::String, articleId::String, newsArticleOptions::NamedTuple=(;)) =
  sendmsg(ib, 84, ### REQ_NEWS_ARTICLE
          maptopb(:NewsArticleRequest; reqId,
                                       providerCode,
                                       articleId,
                                       newsArticleOptions))

reqNewsProviders(ib::Connection) = sendmsg(ib, 85) ### REQ_NEWS_PROVIDERS

reqHistoricalNews(ib::Connection, reqId::Int, conId::Int, providerCodes::String,
                  startDateTime::String, endDateTime::String, totalResults::Int, historicalNewsOptions::NamedTuple=(;)) =
  sendmsg(ib, 86, ### REQ_HISTORICAL_NEWS
          maptopb(:HistoricalNewsRequest; reqId,
                                          conId,
                                          providerCodes,
                                          startDateTime,
                                          endDateTime,
                                          totalResults,
                                          historicalNewsOptions))

reqHeadTimestamp(ib::Connection, reqId::Int, contract::Contract, whatToShow::String, useRTH::Bool, formatDate::Int) =
  sendmsg(ib, 87, ### REQ_HEAD_TIMESTAMP
          maptopb(:HeadTimestampRequest; reqId,
                                         contract,
                                         useRTH,
                                         whatToShow,
                                         formatDate))

reqHistogramData(ib::Connection, reqId::Int, contract::Contract, useRTH::Bool, timePeriod::String) =
  sendmsg(ib, 88, ### REQ_HISTOGRAM_DATA
          maptopb(:HistogramDataRequest; reqId,
                                         contract,
                                         useRTH,
                                         timePeriod))

cancelHistogramData(ib::Connection, reqId::Int) = req_simple(ib, 89, reqId) ### CANCEL_HISTOGRAM_DATA

cancelHeadTimestamp(ib::Connection, reqId::Int) = req_simple(ib, 90, reqId) ### CANCEL_HEAD_TIMESTAMP

reqMarketRule(ib::Connection, marketRuleId::Int) = req_simple(ib, 91, marketRuleId) ### REQ_MARKET_RULE

reqPnL(ib::Connection, reqId::Int, account::String, modelCode::String) =
  sendmsg(ib, 92,  ### REQ_PNL
          maptopb(:PnLRequest; reqId,
                               account,
                               modelCode))

cancelPnL(ib::Connection, reqId::Int) = req_simple(ib, 93, reqId) ### CANCEL_PNL

reqPnLSingle(ib::Connection, reqId::Int, account::String, modelCode::String, conId::Int) =
  sendmsg(ib, 94, ### REQ_PNL_SINGLE
          maptopb(:PnLSingleRequest; reqId,
                                     account,
                                     modelCode,
                                     conId))

cancelPnLSingle(ib::Connection, reqId::Int) = req_simple(ib, 95, reqId) ### CANCEL_PNL_SINGLE

reqHistoricalTicks(ib::Connection, reqId::Int, contract::Contract, startDateTime::String, endDateTime::String,
                   numberOfTicks::Int, whatToShow::String, useRTH::Bool, ignoreSize::Bool, miscOptions::NamedTuple=(;)) =
  sendmsg(ib, 96, ### REQ_HISTORICAL_TICKS
          maptopb(:HistoricalTicksRequest; reqId,
                                           contract,
                                           startDateTime,
                                           endDateTime,
                                           numberOfTicks,
                                           whatToShow,
                                           useRTH,
                                           ignoreSize,
                                           miscOptions))

reqTickByTickData(ib::Connection, reqId::Int, contract::Contract, tickType::String,
                  numberOfTicks::Int, ignoreSize::Bool) =
  sendmsg(ib, 97,
          maptopb(:TickByTickRequest; reqId,
                                      contract,
                                      tickType,
                                      numberOfTicks,
                                      ignoreSize))

cancelTickByTickData(ib::Connection, reqId::Int) = req_simple(ib, 98, reqId) ### CANCEL_TICK_BY_TICK_DATA

reqCompletedOrders(ib::Connection, apiOnly::Bool) = req_simple(ib, 99, apiOnly) ### REQ_COMPLETED_ORDERS

reqWshMetaData(ib::Connection, reqId::Int) = req_simple(ib, 100, reqId) ### REQ_WSH_META_DATA

cancelWshMetaData(ib::Connection, reqId::Int) = req_simple(ib, 101, reqId) ### CANCEL_WSH_META_DATA

function reqWshEventData(ib::Connection, reqId::Int, wshEventData::WshEventData)

  msgid = 102 ### REQ_WSH_EVENT_DATA

  msg = maptopb(wshEventData)

  msg[:reqId] = reqId

  sendmsg(ib, msgid, msg)
end

cancelWshEventData(ib::Connection, reqId::Int) = req_simple(ib, 103, reqId) ### CANCEL_WSH_EVENT_DATA

reqUserInfo(ib::Connection, reqId::Int) = req_simple(ib, 104, reqId) ### REQ_USER_INFO

reqCurrentTimeInMillis(ib::Connection) = sendmsg(ib, 105) ### REQ_CURRENT_TIME_IN_MILLIS

cancelContractData(ib::Connection, reqId::Int) = req_simple(ib, 106, reqId) ### CANCEL_CONTRACT_DATA

cancelHistoricalTick(ib::Connection, reqId::Int) = req_simple(ib, 107, reqId) ### CANCEL_HISTORICAL_TICKS


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
#       verifyAndAuthRequest,
#       verifyAndAuthMessage,
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
       reqCompletedOrders,
       reqWshMetaData,
       cancelWshMetaData,
       reqWshEventData,
       cancelWshEventData,
       reqUserInfo,
       reqCurrentTimeInMillis,
       cancelContractData,
       cancelHistoricalTick
end
