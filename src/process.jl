import ...CommissionReport,
       ...Contract,
       ...ContractDescription,
       ...ContractDetails,
       ...Execution,
       ...FaDataType,
       ...MarketDataType,
       ...Order,
       ...OrderState,
       ...SoftDollarTier,
       ...TickAttrib,
       ...Bar,
       ...VBar,
       ...DepthMktDataDescription,
       ...FamilyCode,
       ...HistogramEntry,
       ...VNewsProvider,
       ...VPriceIncrement,
       ...VSmartComponent,
       ...ScannerDataElement,
       ...Tick,
       ...VTick,
       ...TickBidAsk,
       ...VTickBidAsk,
       ...TickLast,
       ...VTickLast,
       ...funddist,
       ...fundtype,
       ...optexercisetype,
       ...ns,
       ...PB,
       ...splat1,
       ...todouble,
       ...toint,
       ...transform


"""
    process::Dict{Int,Function}

Collection of parsers indexed by message ID
"""
const process = Dict(

  #
  # Messages using ProtoBuf have an offset applied
  #
  #  msgid -> msgid + PROTOBUF_MSG_ID = 200
  #

  # TICK_PRICE
  201 => function(msg, w, ver)

    pb = PB.deserialize(:TickPrice, msg)

    transform(tickname, pb, :tickType)
    todouble(pb, :size)

    # Unmask
    transform(m -> TickAttrib(digits(Bool, m, base=2, pad=3)),
              pb, :attrMask)

    w.tickPrice(splat1(pb; price=nothing, size=nothing)...)
  end,

  # TICK_SIZE
  202 => function(msg, w, ver)

    pb = PB.deserialize(:TickString, msg)

    transform(tickname, pb, :tickType)
    todouble(pb, :value)

    w.tickSize(splat1(pb)...)
  end,

  # ORDER_STATUS
  203 => function(msg, w, ver)

    pb = PB.deserialize(:OrderStatus, msg)

    todouble(pb, :filled)
    todouble(pb, :remaining)

    w.orderStatus(splat1(pb; whyHeld=ns)...)
  end,

  # ERR_MSG
  204 => function(msg, w, ver)

    pb = PB.deserialize(:Error, msg)

    w.error(splat1(pb; errorCode=nothing, advancedOrderRejectJson=ns)...)
  end,

  # OPEN_ORDER
  205 => function(msg, w, ver)

    pb = PB.deserialize(:OpenOrder, msg)

    o = pb[:order]

    # Check orderId
    pb[:orderId] == o[:orderId] ||
      @warn "orderId mismatch" OID=pb[:orderId] OOID=o[:orderId]

    # Conversions
    todouble(o, :totalQuantity)
    todouble(o, :filledQuantity)

    for oa ∈ get(pb[:orderState], :orderAllocations, ()),
        n ∈ (:position,
              :positionDesired,
              :positionAfter,
              :desiredAllocQty,
              :allowedAllocQty)
      todouble(oa, n)
    end

    o[:usePriceMgmtAlgo] ∈ (0, 1) ||
      @warn "unexpected usePriceMgmtAlgo" U=o[:usePriceMgmtAlgo]

    oid,
    contract::Contract,
    order::Order,
    orderState::OrderState = splat1(pb)

    # Transfer comboLeg prices
    # TODO: Fix this
    if PB.has(pb[:contract], :comboLegs)
      ocl = [ get(cl, :perLegPrice, nothing) for cl ∈ pb[:contract][:comboLegs] ]

      n = count(isnothing, ocl)

      if n == 0
        order.orderComboLegs = ocl

      elseif n < length(ocl)
        @warn "perLegPrice: not all filled" ocl
      end
    end

    w.openOrder(oid, contract, order, orderState)
  end,

  # ACCT_VALUE
  206 => function(msg, w, ver)

    pb = PB.deserialize(:AccountValue, msg)

    w.updateAccountValue(splat1(pb; currency=ns)...)
  end,

  # PORTFOLIO_VALUE
  207 => function(msg, w, ver)

    pb = PB.deserialize(:PortfolioValue, msg)

    todouble(pb, :position)

    w.updatePortfolio(splat1(pb)...)
  end,

  # ACCT_UPDATE_TIME
  208 => function(msg, w, ver)

    pb = PB.deserialize(:SingleString, msg)

    w.updateAccountTime(pb[:value])
  end,

  # NEXT_VALID_ID
  209 => (msg, w, ver) -> w.nextValidId(PB.deserialize(:SingleInt32, msg)[:value]),

  # CONTRACT_DATA
  210 => function(msg, w, ver)

    pb = PB.deserialize(:ContractData, msg)

    cd = pb[:contractDetails]
    todouble.(Ref(cd), (:minTick, :minSize, :sizeIncrement, :suggestedSizeIncrement))
    transform(funddist, cd, :fundDistributionPolicyIndicator)
    transform(fundtype, cd, :fundAssetType)

    reqId,
    contract::Contract,
    contractDetails::ContractDetails = splat1(pb)

    contractDetails.contract = contract

    w.contractDetails(reqId, contractDetails)
  end,

  # EXECUTION_DATA
  211 => function(msg, w, ver)

    pb = PB.deserialize(:ExecutionDetails, msg)

    e = pb[:execution]
    todouble(e, :shares)
    todouble(e, :cumQty)
    transform(optexercisetype, e, :optExerciseOrLapseType)

    execution = Execution(splat1(e; liquidation=false,
                                    orderRef=ns,
                                    evRule=ns,
                                    evMultiplier=nothing,
                                    modelCode=ns,
                                    pendingPriceRevision=false,
                                    submitter=ns)...)

    w.execDetails(pb[:reqId], convert(Contract, pb[:contract]), execution)
  end,

  # MARKET_DEPTH
  212 => function(msg, w, ver)

    pb = PB.deserialize(:MarketDepth, msg)

    md = pb[:marketDepthData]

    todouble(md, :size)

    w.updateMktDepth(pb[:reqId], splat1(md, (:position,
                                             :operation,
                                             :side,
                                             :price,
                                             :size))...)
  end,

  # MARKET_DEPTH_L2
  213 => function(msg, w, ver)

    pb = PB.deserialize(:MarketDepth, msg)

    md = pb[:marketDepthData]

    todouble(md, :size)

    w.updateMktDepthL2(pb[:reqId], splat1(md, (:position,
                                               :marketMaker,
                                               :operation,
                                               :side,
                                               :price,
                                               :size,
                                               :isSmartDepth))...)
  end,

  # NEWS_BULLETINS
  214 => function(msg, w, ver)

    pb = PB.deserialize(:NewsBulletin, msg)

    w.updateNewsBulletin(splat1(pb)...)
  end,

  # MANAGED_ACCTS
  215 => (msg, w, ver) -> w.managedAccounts(PB.deserialize(:SingleString, msg)[:value]),

  # RECEIVE_FA
  216 => function(msg, w, ver)

    pb = PB.deserialize(:StringData, msg)

    w.receiveFA(FaDataType(pb[:reqId]), pb[:data])
  end,

  # HISTORICAL_DATA
  217 => function(msg, w, ver)

    pb = PB.deserialize(:HistoricalData, msg)

    bars = map(pb[:bars]) do b
                            todouble(b, :volume)
                            todouble(b, :wap)

                            convert(Bar, b)
                          end

    w.historicalData(pb[:reqId], bars)
  end,

  # BOND_CONTRACT_DATA
  218 => function(msg, w, ver)

    pb = PB.deserialize(:ContractData, msg)

    cd = pb[:contractDetails]

    todouble.(Ref(cd), (:minTick, :minSize, :sizeIncrement, :suggestedSizeIncrement))

    reqId,
    contract::Contract,
    contractDetails::ContractDetails = splat1(pb)

    contractDetails.contract = contract

    w.bondContractDetails(reqId, contractDetails)
  end,

  # SCANNER_PARAMETERS
  219 => (msg, w, ver) -> w.scannerParameters(PB.deserialize(:SingleString, msg)[:value]),

  # SCANNER_DATA
  220 => function(msg, w, ver)

    pb = PB.deserialize(:ScannerData, msg)

    data = map(pb[:data]) do sd

                            ScannerDataElement(splat1(sd; distance=ns,
                                                          benchmark=ns,
                                                          projection=ns,
                                                          comboKey=ns))
                          end

    w.scannerData(pb[:reqId], data)
  end,

  # TICK_OPTION_COMPUTATION
  221 => function(msg, w, ver)

    pb = PB.deserialize(:TickOptionComputation, msg)

    args = Iterators.map(PB.allnames(pb)) do n

            val = pb[n]

            n === :tickType ? tickname(val) :
            val == -1 && n ∈ (:impliedVol, :optPrice, :pvDividend, :undPrice) ? nothing :
            val == -2 && n ∈ (:delta, :gamma, :vega, :theta) ? nothing :
              val
          end

    w.tickOptionComputation(args...)
  end,

  # TICK_GENERIC
  245 => function(msg, w, ver)

    pb = PB.deserialize(:TickGeneric, msg)

    transform(tickname, pb, :tickType)

    w.tickGeneric(splat1(pb)...)
  end,

  # TICK_STRING
  246 => function(msg, w, ver)

    pb = PB.deserialize(:TickString, msg)

    transform(tickname, pb, :tickType)

    w.tickString(splat1(pb)...)
  end,

  # CURRENT_TIME
  249 => (msg, w, ver) -> w.currentTime(PB.deserialize(:SingleInt64, msg)[:value]),

  # REAL_TIME_BARS
  250 => function(msg, w, ver)

    pb = PB.deserialize(:RealTimeBarTick, msg)

    todouble(pb, :volume)
    todouble(pb, :wap)

    w.realtimeBar(splat1(pb)...)
  end,

  # FUNDAMENTAL_DATA
  251 => function(msg, w, ver)

    pb = PB.deserialize(:StringData, msg)

    w.fundamentalData(splat1(pb)...)
  end,

  # CONTRACT_DATA_END
  252 => (msg, w, ver) -> w.contractDetailsEnd(PB.deserialize(:SingleInt32, msg)[:value]),

  # OPEN_ORDER_END
  253 => (msg, w, ver) -> w.openOrderEnd(),

  # ACCT_DOWNLOAD_END
  254 => (msg, w, ver) -> w.accountDownloadEnd(PB.deserialize(:SingleString, msg)[:value]),

  # EXECUTION_DATA_END
  255 => (msg, w, ver) -> w.execDetailsEnd(PB.deserialize(:SingleInt32, msg)[:value]),

  # TICK_SNAPSHOT_END
  257 => (msg, w, ver) -> w.tickSnapshotEnd(PB.deserialize(:SingleInt32, msg)[:value]),

  # MARKET_DATA_TYPE
  258 => function(msg, w, ver)

    pb = PB.deserialize(:MarketDataType, msg)

    w.marketDataType(pb[:reqId], MarketDataType(pb[:marketDataType]))
  end,

  # COMMISSION_REPORT
  259 => function(msg, w, ver)

    pb = PB.deserialize(:CommissionReport, msg)

    toint(pb, :yieldRedemptionDate)

    commission = CommissionReport(splat1(pb; realizedPNL=nothing,
                                             yield=nothing,
                                             yieldRedemptionDate=nothing)...)

    w.commissionReport(commission)
  end,

  # POSITION_DATA
  261 => function(msg, w, ver)

    pb = PB.deserialize(:Position, msg)

    todouble(pb, :position)

    w.position(splat1(pb)...)
  end,

  # POSITION_END
  262 => (msg, w, ver) -> w.positionEnd(),

  # ACCOUNT_SUMMARY
  263 => function(msg, w, ver)

    pb = PB.deserialize(:AccountSummary, msg)

    w.accountSummary(splat1(pb; currency=ns)...)
  end,

  # ACCOUNT_SUMMARY_END
  264 => (msg, w, ver) -> w.accountSummaryEnd(PB.deserialize(:SingleInt32, msg)[:value]),

  # VERIFY_MESSAGE_API
  265 => (msg, w, ver) -> w.verifyMessageAPI(PB.deserialize(:SingleString, msg)[:value]),

  # VERIFY_COMPLETED
  266 => function(msg, w, ver)

    pb = PB.deserialize(:VerifyCompleted, msg)

    w.verifyCompleted(splat1(pb)...)
  end,

  # DISPLAY_GROUP_LIST
  267 => function(msg, w, ver)

    pb = PB.deserialize(:StringData, msg)

    w.displayGroupList(pb[:reqId], pd[:data])
  end,

  # DISPLAY_GROUP_UPDATED
  268 => function(msg, w, ver)

    pb = PB.deserialize(:StringData, msg)

    w.displayGroupUpdated(pb[:reqId], pd[:data])
  end,

  # POSITION_MULTI
  271 => function(msg, w, ver)

    pb = PB.deserialize(:PositionMulti, msg)

    todouble(pb, :position)

    w.positionMulti(splat1(pb, (:reqId,
                                :account,
                                :modelCode,
                                :contract,
                                :position,
                                :avgCost);
                            modelCode=ns)...)
  end,

  # POSITION_MULTI_END
  272 => (msg, w, ver) -> w.positionMultiEnd(PB.deserialize(:SingleInt32, msg)[:value]),

  # ACCOUNT_UPDATE_MULTI
  273 => function(msg, w, ver)

    pb = PB.deserialize(:AccountUpdateMulti, msg)

    w.accountUpdateMulti(splat1(pb; modelCode=ns, currency=ns)...)
  end,

  # ACCOUNT_UPDATE_MULTI_END
  274 => (msg, w, ver) -> w.accountUpdateMultiEnd(PB.deserialize(:SingleInt32, msg)[:value]),

  # SECURITY_DEFINITION_OPTION_PARAMETER
  275 => function(msg, w, ver)

    pb = PB.deserialize(:SecDefOptParameter, msg)

    w.securityDefinitionOptionalParameter(splat1(pb)...)
  end,

  # SECURITY_DEFINITION_OPTION_PARAMETER_END
  276 => (msg, w, ver) -> w.securityDefinitionOptionalParameterEnd(PB.deserialize(:SingleInt32, msg)[:value]),

  # SOFT_DOLLAR_TIERS
  277 => function(msg, w, ver)

    pb = PB.deserialize(:SoftDollarTiers, msg)

    w.softDollarTiers(splat1(pb; tiers=SoftDollarTier[])...)
  end,

  # FAMILY_CODES
  278 => function(msg, w, ver)

    pb = PB.deserialize(:FamilyCodes, msg)

    fc = map(pb[:familyCodes]) do r

                        FamilyCode(splat1(r; familyCode=ns))
                      end

    w.familyCodes(fc)
  end,

  # SYMBOL_SAMPLES
  279 => function(msg, w, ver)

    pb = PB.deserialize(:SymbolSamples, msg)

    cds = PB.has(pb, :contractDescriptions) ? map(pb[:contractDescriptions]) do cd

                                ContractDescription(splat1(cd; derivativeSecTypes=String[])...)
                              end : ContractDescription[]

    w.symbolSamples(pb[:reqId], cds)
  end,

  # MKT_DEPTH_EXCHANGES
  280 => function(msg, w, ver)

    pb = PB.deserialize(:MarketDepthExchanges, msg)

    mde = map(pb[:depthMktDataDescriptions]) do e

                        DepthMktDataDescription(splat1(e; listingExch=ns, aggGroup=nothing))
                      end

    w.mktDepthExchanges(mde)
  end,

  # TICK_REQ_PARAMS
  281 => function(msg, w, ver)

    pb = PB.deserialize(:TickReqParams, msg)

    todouble(pb, :minTick)

    w.tickReqParams(splat1(pb; bboExchange=ns)...)
  end,

  # SMART_COMPONENTS
  282 => function(msg, w, ver)

    pb = PB.deserialize(:SmartComponents, msg)

    w.smartComponents(splat1(pb; map=VSmartComponent())...)
  end,

  # NEWS_ARTICLE
  283 => function(msg, w, ver)

    pb = PB.deserialize(:NewsArticle, msg)

    w.newsArticle(splat1(pb)...)
  end,

  # TICK_NEWS
  284 => function(msg, w, ver)

    pb = PB.deserialize(:TickNews, msg)

    w.tickNews(splat1(pb)...)
  end,

  # NEWS_PROVIDERS
  285 => function(msg, w, ver)

    pb = PB.deserialize(:NewsProviders, msg)

    w.newsProviders(convert(VNewsProvider, splat1(pb; newsProviders=VNewsProvider())...))
  end,

  # HISTORICAL_NEWS
  286 => function(msg, w, ver)

    pb = PB.deserialize(:HistoricalNews, msg)

    w.historicalNews(splat1(pb)...)
  end,

  # HISTORICAL_NEWS_END
  287 => function(msg, w, ver)

    pb = PB.deserialize(:HistoricalNewsEnd, msg)

    w.historicalNewsEnd(splat1(pb)...)
  end,

  # HEAD_TIMESTAMP
  288 => function(msg, w, ver)

    pb = PB.deserialize(:StringData, msg)

    w.headTimestamp(splat1(pb)...)
  end,

  # HISTOGRAM_DATA
  289 => function(msg, w, ver)

    pb = PB.deserialize(:HistogramData, msg)

    data = map(pb[:data]) do d

                            todouble(d, :size)

                            convert(HistogramEntry, d)
                          end

    w.histogramData(pb[:reqId], data)
  end,

  # HISTORICAL_DATA_UPDATE
  290 => function(msg, w, ver)

    pb = PB.deserialize(:HistoricalDataUpdate, msg)

    todouble.(Ref(pb[:bar]), (:volume, :wap))

    reqId,
    bar::Bar = splat1(pb)

    w.historicalDataUpdate(reqId, bar)
  end,

  # REROUTE_MKT_DATA_REQ
  291 => function(msg, w, ver)

    pb = PB.deserialize(:Reroute, msg)

    w.rerouteMktDataReq(splat1(pb)...)
  end,

  # REROUTE_MKT_DEPTH_REQ
  292 => function(msg, w, ver)

    pb = PB.deserialize(:Reroute, msg)

    w.rerouteMktDepthReq(splat1(pb)...)
  end,

  # MARKET_RULE
  293 => function(msg, w, ver)

    pb = PB.deserialize(:MarketRule, msg)

    id,
    priceIncrements::VPriceIncrement = splat1(pb)

    w.marketRule(id, priceIncrements)
  end,

  # PNL
  294 => function(msg, w, ver)

    pb = PB.deserialize(:PnL, msg)

    w.pnl(splat1(pb)...)
  end,

  # PNL_SINGLE
  295 => function(msg, w, ver)

    pb = PB.deserialize(:PnLSingle, msg)

    todouble(pb, :position)

    w.pnlSingle(splat1(pb; dailyPnL=nothing, realizedPnL=nothing)...)
  end,

  # HISTORICAL_TICKS
  296 => function(msg, w, ver)

    pb = PB.deserialize(:HistoricalTicks, msg)

    ticks = PB.has(pb, :ticks) ? map(pb[:ticks]) do t

                                    todouble(t, :size)

                                    convert(Tick, t)
                                  end : VTick()

    w.historicalTicks(pb[:reqId], ticks, pb[:done])
  end,

  # HISTORICAL_TICKS_BID_ASK
  297 => function(msg, w, ver)

    pb = PB.deserialize(:HistoricalTicksBidAsk, msg)

    ticks = PB.has(pb, :ticks) ? map(pb[:ticks]) do t

                                    todouble(t, :bidSize)
                                    todouble(t, :askSize)

                                    TickBidAsk(splat1(t))
                                  end : VTickBidAsk()

    w.historicalTicksBidAsk(pb[:reqId], ticks, pb[:done])
  end,

  # HISTORICAL_TICKS_LAST
  298 => function(msg, w, ver)

    pb = PB.deserialize(:HistoricalTicksLast, msg)

    ticks = PB.has(pb, :ticks) ? map(pb[:ticks]) do t

                                    todouble(t, :size)

                                    TickLast(splat1(t; exchange=ns,
                                                       specialConditions=ns))
                                  end : VTickLast()

    w.historicalTicksLast(pb[:reqId], ticks, pb[:done])
  end,

  # TICK_BY_TICK
  299 => function(msg, w, ver)

    pb = PB.deserialize(:TickByTickData, msg)

    reqId = pb[:reqId]
    tickType = pb[:tickType]

    if tickType ∈ (1, 2)

      tick = pb[:tickLast]

      todouble(tick, :size)

      w.tickByTickAllLast(reqId, tickType, splat1(tick, (:time,
                                                         :price,
                                                         :size,
                                                         :attribs,
                                                         :exchange,
                                                         :specialConditions);
                                                        exchange=ns,
                                                        specialConditions=ns)...)
    elseif tickType == 3

      tick = pb[:tickBidAsk]

      todouble(tick, :bidSize)
      todouble(tick, :askSize)

      w.tickByTickBidAsk(reqId, splat1(tick, (:time,
                                              :bidPrice,
                                              :askPrice,
                                              :bidSize,
                                              :askSize,
                                              :attribs))...)
    elseif tickType == 4

      tick = pb[:tickMidPoint]

      w.tickByTickMidPoint(reqId, tick[:time], tick[:price])
    else

      @warn "TICK_BY_TICK: unknown ticktype" T=ticktype
    end
  end,

  # ORDER_BOUND
  300 => function(msg, w, ver)

    pb = PB.deserialize(:OrderBound, msg)

    w.orderBound(splat1(pb)...)
  end,

  # COMPLETED_ORDER
  301 => function(msg, w, ver)

    pb = PB.deserialize(:CompletedOrder, msg)

    # Conversions
    todouble(pb[:order], :totalQuantity)
    todouble(pb[:order], :filledQuantity)

    pb[:order][:usePriceMgmtAlgo] ∈ (0, 1) ||
      @warn "unexpected usePriceMgmtAlgo" U=pb[:order][:usePriceMgmtAlgo]

    contract::Contract,
    order::Order,
    orderState::OrderState = splat1(pb)

    # Transfer comboLeg prices
    if PB.has(pb[:contract], :comboLegs)
      ocl = [ get(cl, :perLegPrice, nothing) for cl ∈ pb[:contract][:comboLegs] ]

      n = count(isnothing, ocl)

      if n == 0
        order.orderComboLegs = ocl

      elseif n < length(ocl)
        @warn "perLegPrice: not all filled" ocl
      end
    end

    w.completedOrder(contract, order, orderState)
  end,

  # COMPLETED_ORDERS_END
  302 => (msg, w, ver) -> w.completedOrdersEnd(),

  # REPLACE_FA_END
  303 => function(msg, w, ver)

    pb = PB.deserialize(:StringData, msg)

    w.replaceFAEnd(splat1(pb)...)
  end,

  # WSH_META_DATA
  304 => function(msg, w, ver)

    pb = PB.deserialize(:StringData, msg)

    w.wshMetaData(splat1(pb)...)
  end,

  # WSH_EVENT_DATA
  305 => function(msg, w, ver)

    pb = PB.deserialize(:StringData, msg)

    w.wshEventData(splat1(pb)...)
  end,

  # HISTORICAL_SCHEDULE
  306 => function(msg, w, ver)

    pb = PB.deserialize(:HistoricalSchedule, msg)

    w.historicalSchedule(splat1(pb)...)
  end,

  # USER_INFO
  307 => function(msg, w, ver)

    pb = PB.deserialize(:StringData, msg)

    w.userInfo(splat1(pb)...)
  end,

  # HISTORICAL_DATA_END
  308 => function(msg, w, ver)

    pb = PB.deserialize(:HistoricalDataEnd, msg)

    w.historicalDataEnd(splat1(pb)...)
  end,

  # CURRENT_TIME_IN_MILLIS
  309 => function(msg, w, ver)

    pb = PB.deserialize(:SingleInt64, msg)

    w.currentTimeInMillis(pb[:value])
  end

)
