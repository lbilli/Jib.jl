import ...Bar,
       ...ComboLeg,
       ...CommissionReport,
       ...ConditionType,
       ...Contract,
       ...ContractDescription,
       ...ContractDetails,
       ...DeltaNeutralContract,
       ...Execution,
       ...FamilyCode,
       ...FaDataType,
       ...MarketDataType,
       ...Order,
       ...OrderState,
       ...SoftDollarTier,
       ...TickAttrib,
       ...TickAttribLast,
       ...TickAttribBidAsk,
       ...condition_map,
       ...funddist,
       ...fundtype,
       ...ns


"""
    slurp(::Type{T}, it)

Utility functions to read from an iterator `it` and convert to types `T`.
"""
slurp(::Type{T}, it) where T<:Union{Bool,Int,Enum{Int32},Float64,String,Symbol} = convert(T, pop(it))

slurp(::Type{T}, it) where T = T(take(it, fieldcount(T))...)

slurp(t, it) = slurp.(t, Ref(it))

slurp!(x::T, idx, it) where T = for i ∈ idx
                                  setfield!(x, i, convert(fieldtype(T, i), pop(it)))
                                end

"""
    tagvalue2nt(n, it)

Return a `NamedTuple` by popping `2n` elements from `it`:

    ["tag1", "value1", "tag2", "value2", ...] -> (tag1="value1", tag2="value2", ...)
"""
tagvalue2nt(n, it) = (; (slurp(Symbol, it) => slurp(String, it) for _ ∈ 1:n)...)


function unmask(T::Type{NamedTuple{M,NTuple{N,Bool}}}, mask) where {M,N}

  a = digits(Bool, mask, base=2, pad=N)

  length(a) == N || @error "unmask(): wrong attribs" T mask

  T(a)
end


function fill_table(cols, n::Int, it, Tab::Type{<:Dict}=Dict)

  dict = Tab{Symbol, Vector}()

  for (k, T) ∈ pairs(cols)
    symb = Symbol(k)
    dict[symb] = Vector{T}(undef, n)
  end
  
  for r ∈ 1:n, c ∈ keys(dict)
    dict[c][r] = pop(it)
  end

  dict
end


"""
    process::Dict{Int,Function}

Collection of parsers indexed by message ID
"""
const process = Dict(

  # TICK_PRICE
   1 => function(it, w, ver, Tab=Dict)

          tickerId::Int,
          ticktype::Int,
          price::Union{Float64,Nothing},
          size::Union{Float64,Nothing},
          mask::Int = it

          w.tickPrice(tickerId, tickname(ticktype), price, size, unmask(TickAttrib, mask))
        end,

  # TICK_SIZE
   2 => function(it, w, ver, Tab=Dict)

          tickerId::Int,
          ticktype::Int,
          size::Float64 = it

          w.tickSize(tickerId, tickname(ticktype), size)
        end,

  # ORDER_STATUS
   3 => (it, w, ver, Tab=Dict) -> w.orderStatus(slurp((Int,String,Float64,Float64,Float64,Int,Int,Float64,Int,String,Float64), it)...),

  # ERR_MSG
   4 => (it, w, ver, Tab=Dict) -> w.error(slurp((Int,Int,String,String), it)...),

  # OPEN_ORDER
   5 => function(it, w, ver, Tab=Dict)

          o = Order()
          c = Contract()

          o.orderId = pop(it)

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

          ver < Client.FA_PROFILE_DESUPPORT && pop(it) # Deprecated sharesAllocation

          slurp!(o, (:faGroup,
                     :faMethod,
                     :faPercentage), it)

          pop(it) # Deprecated faProfile

          slurp!(o, (:modelCode,
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

          c.comboLegsDescrip = pop(it)

          # ComboLegs
          n::Int = pop(it)

          for _ ∈ 1:n
            push!(c.comboLegs, slurp(ComboLeg, it))
          end

          # OrderComboLeg
          n = pop(it)
          append!(o.orderComboLegs, take(it, n))

          # SmartComboRouting
          n = pop(it)
          n > 0 && (o.smartComboRoutingParams = tagvalue2nt(n, it))

          slurp!(o, (:scaleInitLevelSize,
                     :scaleSubsLevelSize,
                     :scalePriceIncrement), it)

          !isnothing(o.scalePriceIncrement) &&
          o.scalePriceIncrement > 0         && slurp!(o, 69:75, it) # :scalePriceAdjustValue -> :scaleRandomPercent

          o.hedgeType = pop(it)

          !isempty(o.hedgeType) && (o.hedgeParam = pop(it))

          slurp!(o, (:optOutSmartRouting,
                     :clearingAccount,
                     :clearingIntent,
                     :notHeld), it)

          # DeltaNeutralContract
          slurp(Bool, it) && (c.deltaNeutralContract = slurp(DeltaNeutralContract, it))

          # AlgoStrategy
          o.algoStrategy = pop(it)

          if !isempty(o.algoStrategy)
            n = pop(it)
            n > 0 && (o.algoParams = tagvalue2nt(n, it))
          end

          o.solicited,
          o.whatIf = it

          os = OrderState(take(it, 15)..., ns, ns)

          o.randomizeSize,
          o.randomizePrice = it

          o.orderType == "PEG BENCH" && slurp!(o, (:referenceContractId,
                                                   :isPeggedChangeAmountDecrease,
                                                   :peggedChangeAmount,
                                                   :referenceChangeAmount,
                                                   :referenceExchangeId), it)

          # Conditions
          n = pop(it)

          if n > 0
            for _ ∈ 1:n
              push!(o.conditions, slurp(condition_map[slurp(ConditionType, it)], it))
            end

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
                     :adjustableTrailingUnit), it)

          o.softDollarTier = slurp(SoftDollarTier, it)

          slurp!(o, (:cashQty,
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
                     :midOffsetAtHalf), it)

          ver ≥ Client.CUSTOMER_ACCOUNT && (o.customerAccount = pop(it))

          ver ≥ Client.PROFESSIONAL_CUSTOMER && (o.professionalCustomer = pop(it))

          w.openOrder(o.orderId, c, o, os)
        end,

  # ACCT_VALUE
   6 => (it, w, ver, Tab=Dict) -> w.updateAccountValue(collect(String, take(it, 4))...),

  # PORTFOLIO_VALUE
   7 => function(it, w, ver, Tab=Dict)

          c = Contract()

          slurp!(c, [1:7; 9:12], it)

          w.updatePortfolio(c, collect(Float64, take(it, 6))..., slurp(String, it))
        end,

  # ACCT_UPDATE_TIME
   8 => (it, w, ver, Tab=Dict) -> w.updateAccountTime(slurp(String, it)),

  # NEXT_VALID_ID
   9 => (it, w, ver, Tab=Dict) -> w.nextValidId(slurp(Int, it)),

  # CONTRACT_DATA
  10 => function(it, w, ver, Tab=Dict)

          reqId::Int = pop(it)

          cd = ContractDetails()

          slurp!(cd.contract, 2:4, it)

          ver ≥ Client.LAST_TRADE_DATE && (cd.contract.lastTradeDate = pop(it))

          slurp!(cd.contract, (5, 6, 8, 10, 11), it)

          cd.marketName,
          cd.contract.tradingClass,
          cd.contract.conId,
          cd.minTick,
          cd.contract.multiplier = it

          slurp!(cd, 4:8, it)
          cd.contract.primaryExchange = pop(it)
          slurp!(cd, 9:17, it)

          n::Int = pop(it)
          n > 0 && (cd.secIdList = tagvalue2nt(n, it))

          slurp!(cd, (:aggGroup,
                      :underSymbol,
                      :underSecType,
                      :marketRuleIds,
                      :realExpirationDate,
                      :stockType,
                      :minSize,
                      :sizeIncrement,
                      :suggestedSizeIncrement), it)

          if ver ≥ Client.FUND_DATA_FIELDS && cd.contract.secType == "FUND"

            slurp!(cd, 44:58, it)

            cd.fundDistributionPolicyIndicator = funddist(slurp(String, it))
            cd.fundAssetType = fundtype(slurp(String, it))
          end

          w.contractDetails(reqId, cd)
        end,

  # EXECUTION_DATA
  11 => function(it, w, ver, Tab=Dict)

          reqId::Int,
          orderId = it

          c = Contract()
          slurp!(c, [1:8; 10:12], it)

          args = collect(take(it, 17))  # Must materialize

          e = Execution(orderId,
                        args...,
                        ver ≥ Client.PENDING_PRICE_REVISION ? pop(it) : false)

          w.execDetails(reqId, c, e)
        end,

  # MARKET_DEPTH
  12 => (it, w, ver, Tab=Dict) -> w.updateMktDepth(slurp((Int,Int,Int,Int,Float64,Float64), it)...),

  # MARKET_DEPTH_L2
  13 => (it, w, ver, Tab=Dict) -> w.updateMktDepthL2(slurp((Int,Int,String,Int,Int,Float64,Float64,Bool), it)...),

  # NEWS_BULLETINS
  14 => (it, w, ver, Tab=Dict) -> w.updateNewsBulletin(slurp((Int,Int,String,String), it)...),

  # MANAGED_ACCTS
  15 => (it, w, ver, Tab=Dict) -> w.managedAccounts(slurp(String, it)),

  # RECEIVE_FA
  16 => (it, w, ver, Tab=Dict) -> w.receiveFA(slurp((FaDataType,String), it)...),

  # HISTORICAL_DATA
  17 => function(it, w, ver, Tab=Dict)

          reqId::Int = pop(it)

          pop(it) # Ignore startDate
          pop(it) # Ignore endDate

          n::Int = pop(it)

          df = fill_table((time=String, open=Float64, high=Float64, low=Float64,
                        close=Float64, volume=Float64, wap=Float64, count=Int),
                       n, it, Tab)

          w.historicalData(reqId, df)
        end,

  # BOND_CONTRACT_DATA
  18 => function(it, w, ver, Tab=Dict)

          reqId::Int = pop(it)

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
                      :longName,
                      :evRule,
                      :evMultiplier), it)

          n::Int = pop(it)
          n > 0 && (cd.secIdList = tagvalue2nt(n, it))

          slurp!(cd, (:aggGroup,
                      :marketRuleIds,
                      :minSize,
                      :sizeIncrement,
                      :suggestedSizeIncrement), it)

          w.bondContractDetails(reqId, cd)
        end,

  # SCANNER_PARAMETERS
  19 => (it, w, ver, Tab=Dict) -> w.scannerParameters(slurp(String, it)),

  # SCANNER_DATA
  20 => function(it, w, ver, Tab=Dict)

          tickerId::Int,
          n::Int = it

          rank = Vector{Int}(undef, n)
          cd = [ContractDetails() for _ ∈ 1:n]
          distance =   Vector{String}(undef, n)
          benchmark =  Vector{String}(undef, n)
          projection = Vector{String}(undef, n)
          legsStr =    Vector{String}(undef, n)

          for i ∈ 1:n

            rank[i] = pop(it)

            slurp!(cd[i].contract, [1:6; 8; 10; 11], it)

            cd[i].marketName,
            cd[i].contract.tradingClass,
            distance[i],
            benchmark[i],
            projection[i],
            legsStr[i] = it
          end

          w.scannerData(tickerId, rank, cd, distance, benchmark, projection, legsStr)
        end,

  # TICK_OPTION_COMPUTATION
  21 => function(it, w, ver, Tab=Dict)

          tickerId::Int,
          ticktype::Int,
          tickAttrib::Int = it

          v = collect(Union{Float64,Nothing}, take(it, 8))

          # (impliedVol, optPrice, pvDividend, undPrice) == -1 means NA
          replace!(view(v, [1, 3, 4, 8]), -1 => nothing)

          # (delta, gamma, vega, theta) == -2 means NA
          replace!(view(v, [2, 5, 6, 7]), -2 => nothing)

          w.tickOptionComputation(tickerId, tickname(ticktype), tickAttrib, v...)
        end,

  # TICK_GENERIC
  45 => function(it, w, ver, Tab=Dict)

          tickerId::Int,
          ticktype::Int,
          value::Float64 = it

          w.tickGeneric(tickerId, tickname(ticktype), value)
        end,

  # TICK_STRING
  46 => function(it, w, ver, Tab=Dict)

          tickerId::Int,
          ticktype::Int,
          value::String = it

          w.tickString(tickerId, tickname(ticktype), value)
        end,

  # TICK_EFP
  47 => function(it, w, ver, Tab=Dict)

          tickerId::Int,
          ticktype::Int = it

          w.tickEFP(tickerId, tickname(ticktype), slurp((Float64,String,Float64,Int,String,Float64,Float64), it)...)
        end,

  # CURRENT_TIME
  49 => (it, w, ver, Tab=Dict) -> w.currentTime(slurp(Int, it)),

  # REAL_TIME_BARS
  50 => (it, w, ver, Tab=Dict) -> w.realtimeBar(slurp((Int,Int,Float64,Float64,Float64,Float64,Float64,Float64,Int), it)...),

  # FUNDAMENTAL_DATA
  51 => (it, w, ver, Tab=Dict) -> w.fundamentalData(slurp((Int,String), it)...),

  # CONTRACT_DATA_END
  52 => (it, w, ver, Tab=Dict) -> w.contractDetailsEnd(slurp(Int, it)),

  # OPEN_ORDER_END
  53 => (it, w, ver, Tab=Dict) -> w.openOrderEnd(),

  # ACCT_DOWNLOAD_END
  54 => (it, w, ver, Tab=Dict) -> w.accountDownloadEnd(slurp(String, it)),

  # EXECUTION_DATA_END
  55 => (it, w, ver, Tab=Dict) -> w.execDetailsEnd(slurp(Int, it)),

  # DELTA_NEUTRAL_VALIDATION
  56 => function(it, w, ver, Tab=Dict)

          reqId::Int = pop(it)

          w.deltaNeutralValidation(reqId, slurp(DeltaNeutralContract, it))
        end,

  # TICK_SNAPSHOT_END
  57 => (it, w, ver, Tab=Dict) -> w.tickSnapshotEnd(slurp(Int, it)),

  # MARKET_DATA_TYPE
  58 => (it, w, ver, Tab=Dict) -> w.marketDataType(slurp((Int,MarketDataType), it)...),

  # COMMISSION_REPORT
  59 => (it, w, ver, Tab=Dict) -> w.commissionReport(slurp(CommissionReport, it)),

  # POSITION_DATA
  61 => function(it, w, ver, Tab=Dict)

          account::String = pop(it)

          c = Contract()
          slurp!(c, [1:8; 10:12], it)

          w.position(account, c, collect(Float64, take(it, 2))...)
        end,

  # POSITION_END
  62 => (it, w, ver, Tab=Dict) -> w.positionEnd(),

  # ACCOUNT_SUMMARY
  63 => function(it, w, ver, Tab=Dict)

          reqId::Int = pop(it)

          w.accountSummary(reqId, collect(String, take(it, 4))...)
        end,

  # ACCOUNT_SUMMARY_END
  64 => (it, w, ver, Tab=Dict) -> w.accountSummaryEnd(slurp(Int, it)),

  # VERIFY_MESSAGE_API
  65 => (it, w, ver, Tab=Dict) -> w.verifyMessageAPI(slurp(String, it)),

  # VERIFY_COMPLETED
  66 => (it, w, ver, Tab=Dict) -> w.verifyCompleted(slurp((Bool,String), it)...),

  # DISPLAY_GROUP_LIST
  67 => (it, w, ver, Tab=Dict) -> w.displayGroupList(slurp((Int,String), it)...),

  # DISPLAY_GROUP_UPDATED
  68 => (it, w, ver, Tab=Dict) -> w.displayGroupUpdated(slurp((Int,String), it)...),

  # VERIFY_AND_AUTH_MESSAGE_API
  69 => (it, w, ver, Tab=Dict) -> w.verifyAndAuthMessageAPI(collect(String, take(it, 2))...),

  # VERIFY_AND_AUTH_COMPLETED
  70 => (it, w, ver, Tab=Dict) -> w.verifyAndAuthCompleted(slurp((Bool,String), it)...),

  # POSITION_MULTI
  71 => function(it, w, ver, Tab=Dict)

          reqId::Int,
          account::String = it

          c = Contract()
          slurp!(c, [1:8; 10:12], it)

          position::Float64,
          avgCost::Float64,
          modelCode::String = it

          w.positionMulti(reqId, account, modelCode, c, position, avgCost)
        end,

  # POSITION_MULTI_END
  72 => (it, w, ver, Tab=Dict) -> w.positionMultiEnd(slurp(Int, it)),

  # ACCOUNT_UPDATE_MULTI
  73 => (it, w, ver, Tab=Dict) -> w.accountUpdateMulti(slurp(Int, it), collect(String, take(it, 5))...),

  # ACCOUNT_UPDATE_MULTI_END
  74 => (it, w, ver, Tab=Dict) -> w.accountUpdateMultiEnd(slurp(Int, it)),

  # SECURITY_DEFINITION_OPTION_PARAMETER
  75 => function(it, w, ver, Tab=Dict)

          args = slurp((Int,String,Int,String,String), it)

          ne::Int = pop(it)
          expirations = collect(String, take(it, ne))

          ns::Int = pop(it)
          strikes = collect(Float64, take(it, ns))

          w.securityDefinitionOptionalParameter(args..., expirations, strikes)
        end,

  # SECURITY_DEFINITION_OPTION_PARAMETER_END
  76 => (it, w, ver, Tab=Dict) -> w.securityDefinitionOptionalParameterEnd(slurp(Int, it)),

  # SOFT_DOLLAR_TIERS
  77 => function(it, w, ver, Tab=Dict)

          reqId::Int,
          n::Int = it

          w.softDollarTiers(reqId, [slurp(SoftDollarTier, it) for _ ∈ 1:n])
        end,

  # FAMILY_CODES
  78 => function(it, w, ver, Tab=Dict)

          n::Int = pop(it)

          w.familyCodes([slurp(FamilyCode, it) for _ ∈ 1:n])
        end,

  # SYMBOL_SAMPLES
  79 => function(it, w, ver, Tab=Dict)

          reqId::Int,
          n::Int = it

          cd = map(1:n) do _

                  c = Contract()

                  slurp!(c, (:conId,
                             :symbol,
                             :secType,
                             :primaryExchange,
                             :currency), it)

                  nd::Int = pop(it)

                  dst = collect(String, take(it, nd))

                  slurp!(c, (:description,
                             :issuerId), it)

                  ContractDescription(c, dst)
                end

          w.symbolSamples(reqId, cd)
        end,

  # MKT_DEPTH_EXCHANGES
  80 => function(it, w, ver, Tab=Dict)

          n::Int = pop(it)

          df = fill_table((exchange=String, secType=String, listingExch=String,
                        serviceDataType=String, aggGroup=Union{Int,Nothing}),
                       n, it, Tab)

          w.mktDepthExchanges(df)
        end,

  # TICK_REQ_PARAMS
  81 => (it, w, ver, Tab=Dict) -> w.tickReqParams(slurp((Int,Float64,String,Int), it)...),

  # SMART_COMPONENTS
  82 => function(it, w, ver, Tab=Dict)

          reqId::Int,
          n::Int = it

          df = fill_table((bit=Int, exchange=String, exchangeLetter=String), n, it, Tab)

          w.smartComponents(reqId, df)
        end,

  # NEWS_ARTICLE
  83 => (it, w, ver, Tab=Dict) -> w.newsArticle(slurp((Int,Int,String), it)...),

  # TICK_NEWS
  84 => function (it, w, ver, Tab=Dict)

          args = slurp((Int,Int,String,String,String,String), it)

          w.tickNews(args...)
        end,

  # NEWS_PROVIDERS
  85 => function(it, w, ver, Tab=Dict)

          n::Int = pop(it)

          df = fill_table((providerCode=String, providerName=String), n, it)

          w.newsProviders(df)
        end,

  # HISTORICAL_NEWS
  86 => (it, w, ver, Tab=Dict) -> w.historicalNews(slurp((Int,String,String,String,String), it)...),

  # HISTORICAL_NEWS_END
  87 => (it, w, ver, Tab=Dict) -> w.historicalNewsEnd(slurp((Int,Bool), it)...),

  # HEAD_TIMESTAMP
  88 => (it, w, ver, Tab=Dict) -> w.headTimestamp(slurp((Int,String), it)...),

  # HISTOGRAM_DATA
  89 => function(it, w, ver, Tab=Dict)

          reqId::Int,
          n::Int = it

          df = fill_table((price=Float64, size=Float64), n, it)

          w.histogramData(reqId, df)
        end,

  # HISTORICAL_DATA_UPDATE
  90 => function(it, w, ver, Tab=Dict)

          reqId::Int = pop(it)

          w.historicalDataUpdate(reqId, slurp(Bar, it))
        end,

  # REROUTE_MKT_DATA_REQ
  91 => (it, w, ver, Tab=Dict) -> w.rerouteMktDataReq(slurp((Int,Int,String), it)...),

  # REROUTE_MKT_DEPTH_REQ
  92 => (it, w, ver, Tab=Dict) -> w.rerouteMktDepthReq(slurp((Int,Int,String), it)...),

  # MARKET_RULE
  93 => function(it, w, ver, Tab=Dict)

          marketRuleId::Int,
          n::Int = it

          df = fill_table((lowEdge=Float64, increment=Float64), n, it)

          w.marketRule(marketRuleId, df)
        end,

  # PNL
  94 => function(it, w, ver, Tab=Dict)

          reqId::Int,
          dailyPnL::Float64,
          unrealizedPnL::Float64,
          realizedPnL::Float64 = it

          w.pnl(reqId, dailyPnL, unrealizedPnL, realizedPnL)
        end,

  # PNL_SINGLE
  95 => function(it, w, ver, Tab=Dict)

          reqId::Int,
          pos::Int,
          dailyPnL::Float64,
          unrealizedPnL::Union{Float64,Nothing},
          realizedPnL::Union{Float64,Nothing},
          value::Float64 = it

          w.pnlSingle(reqId, pos, dailyPnL, unrealizedPnL, realizedPnL, value)

        end,

  # HISTORICAL_TICKS
  96 => function(it, w, ver, Tab=Dict)

          reqId::Int,
          n::Int = it

          df = fill_table((time=Int, ignore=Int, price=Float64, size=Float64), n, it)

          select!(df, Not(:ignore))

          done::Bool = pop(it)

          w.historicalTicks(reqId, df, done)
        end,

  # HISTORICAL_TICKS_BID_ASK
  97 => function(it, w, ver, Tab=Dict)

          reqId::Int,
          n::Int = it

          df = fill_table((time=Int, mask=Int, priceBid=Float64, priceAsk=Float64,
                        sizeBid=Float64, sizeAsk=Float64),
                       n, it)

          # TODO: Unmask df.mask

          done::Bool = pop(it)

          w.historicalTicksBidAsk(reqId, df, done)
        end,

  # HISTORICAL_TICKS_LAST
  98 => function(it, w, ver, Tab=Dict)

          reqId::Int,
          n::Int = it

          df = fill_table((time=Int, mask=Int, price=Float64, size=Float64,
                        exchange=String, specialConditions=String),
                       n, it)

          # TODO: Unmask df.mask

          done::Bool = pop(it)

          w.historicalTicksLast(reqId, df, done)
        end,

  # TICK_BY_TICK
  99 => function(it, w, ver, Tab=Dict)

          reqId::Int,
          ticktype::Int,
          time::Int = it

          local mask::Int  # To avoid "multiple type declarations" error

          if ticktype ∈ (1, 2)

            price::Float64,
            size::Float64,
            mask,
            exchange::String,
            specialConditions::String = it

            w.tickByTickAllLast(reqId, ticktype, time, price, size, unmask(TickAttribLast, mask), exchange, specialConditions)

          elseif ticktype == 3

            bidPrice::Float64,
            askPrice::Float64,
            bidSize::Float64,
            askSize::Float64,
            mask = it

            w.tickByTickBidAsk(reqId, time, bidPrice, askPrice, bidSize, askSize, unmask(TickAttribBidAsk, mask))

          elseif ticktype == 4

            w.tickByTickMidPoint(reqId, time, slurp(Float64, it))

          else
            @warn "TICK_BY_TICK: unknown ticktype" T=ticktype
          end
        end,

  # ORDER_BOUND
 100 => (it, w, ver, Tab=Dict) -> w.orderBound(collect(Int, take(it, 3))...),

  # COMPLETED_ORDER
 101 => function(it, w, ver, Tab=Dict)

          o = Order()
          c = Contract()

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
                     :faPercentage), it)

          ver < Client.FA_PROFILE_DESUPPORT && pop(it) # Deprecated faProfile

          slurp!(o, (:modelCode,
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

          c.comboLegsDescrip = pop(it)

          # ComboLegs
          n::Int = pop(it)

          for _ ∈ 1:n
            push!(c.comboLegs, slurp(ComboLeg, it))
          end

          # OrderComboLeg
          n = pop(it)
          append!(o.orderComboLegs, take(it, n))

          # SmartComboRouting
          n = pop(it)
          n > 0 && (o.smartComboRoutingParams = tagvalue2nt(n, it))

          slurp!(o, (:scaleInitLevelSize,
                     :scaleSubsLevelSize,
                     :scalePriceIncrement), it)

          !isnothing(o.scalePriceIncrement) &&
          o.scalePriceIncrement > 0         && slurp!(o, 69:75, it) # :scalePriceAdjustValue -> :scaleRandomPercent

          o.hedgeType = pop(it)

          !isempty(o.hedgeType) && (o.hedgeParam = pop(it))

          slurp!(o, (:clearingAccount,
                     :clearingIntent,
                     :notHeld), it)

          # DeltaNeutralContract
          slurp(Bool, it) && (c.deltaNeutralContract = slurp(DeltaNeutralContract, it))

          # AlgoStrategy
          o.algoStrategy = pop(it)

          if !isempty(o.algoStrategy)
            n = pop(it)
            n > 0 && (o.algoParams = tagvalue2nt(n, it))
          end

          o.solicited,
          ostatus::String,     # OrderState.status
          o.randomizeSize,
          o.randomizePrice = it

          o.orderType == "PEG BENCH" && slurp!(o, (:referenceContractId,
                                                   :isPeggedChangeAmountDecrease,
                                                   :peggedChangeAmount,
                                                   :referenceChangeAmount,
                                                   :referenceExchangeId), it)

          # Conditions
          n = pop(it)

          if n > 0
            for _ ∈ 1:n
              push!(o.conditions, slurp(condition_map[slurp(ConditionType, it)], it))
            end

            o.conditionsIgnoreRth,
            o.conditionsCancelOrder = it
          end

          slurp!(o, (:trailStopPrice,
                     :lmtPriceOffset,
                     :cashQty,
                     :dontUseAutoPriceForHedge,
                     :isOmsContainer), it)

          slurp!(o, 118:125, it) # :autoCancelDate -> :parentPermId

          os = OrderState(ostatus, fill(ns, 9)..., fill(nothing, 3)..., ns, ns, take(it, 2)...)

          slurp!(o, (:minTradeQty,
                     :minCompeteSize,
                     :competeAgainstBestOffset,
                     :midOffsetAtWhole,
                     :midOffsetAtHalf), it)

          ver ≥ Client.CUSTOMER_ACCOUNT && (o.customerAccount = pop(it))

          ver ≥ Client.PROFESSIONAL_CUSTOMER && (o.professionalCustomer = pop(it))

          w.completedOrder(c, o, os)
         end,

  # COMPLETED_ORDERS_END
 102 => (it, w, ver, Tab=Dict) -> w.completedOrdersEnd(),

  # REPLACE_FA_END
 103 => (it, w, ver, Tab=Dict) -> w.replaceFAEnd(slurp((Int,String), it)...),

 # WSH_META_DATA
 104 => (it, w, ver, Tab=Dict) -> w.wshMetaData(slurp((Int,String), it)...),

 # WSH_EVENT_DATA
 105 => (it, w, ver, Tab=Dict) -> w.wshEventData(slurp((Int,String), it)...),

 # HISTORICAL_SCHEDULE
 106 => function(it, w, ver, Tab=Dict)

          reqId::Int,
          startDateTime::String,
          endDateTime::String,
          timeZone::String,
          n::Int = it

          df = fill_table((startDateTime=String, endDateTime=String, refDate=String), n, it)

          w.historicalSchedule(reqId, startDateTime, endDateTime, timeZone, df)
        end,

  # USER_INFO
  107 => (it, w, ver, Tab=Dict) -> w.userInfo(slurp((Int,String), it)...)
)
