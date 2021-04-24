using DataFrames

import ...ComboLeg,
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
       ...ns


"""
    slurp(::Type{T}, it)

Utility functions to read from an iterator `it` and convert to types `T`.
"""
slurp(::Type{T}, it) where T<:Union{Bool,Int,Enum{Int32},Float64,String} = convert(T, pop(it))

slurp(::Type{T}, it) where T = T(take(it, fieldcount(T))...)

slurp(t, it) = convert.(t, take(it, length(t)))

slurp!(x::T, idx, it) where T = setfield!.(Ref(x), idx, slurp(fieldtype.(T, idx), it))


"""
    tagvalue2nt(x)

Convert a `String[]` into a `NamedTuple` like this:

    ["tag1", "value1", "tag2", "value2", ...] -> (tag1="value1", tag2="value2", ...)
"""
function tagvalue2nt(x)

  @assert iseven(length(x))

  s = collect(String, x)

  (; (Symbol(t) => v for (t, v) ∈ Iterators.partition(s, 2))...)
end


function unmask(T::Type{NamedTuple{M,NTuple{N,Bool}}}, mask) where {M,N}

  a = digits(Bool, mask, base=2, pad=N)

  length(a) == N || @error "unmask(): wrong attribs" T mask

  T(a)
end


function fill_df(eltypes, names, n, it)

  df = DataFrame([Vector{T}(undef, n) for T ∈ eltypes], names; copycols=false)

  for r ∈ 1:nrow(df), c ∈ 1:ncol(df)
    df[r, c] = pop(it)
  end

  df
end


"""
    process::Dict{Int,Function}

Collection of parsers indexed by message ID
"""
const process = Dict{Int,Function}(    # TODO Use a Tuple instead?

  # TICK_PRICE
   1 => function(it, w, ver)

          tickerId::Int,
          ticktype::Int,
          price::Float64,
          size::Int,
          mask::Int = it

          w.tickPrice(tickerId, tickname(ticktype), price, size, unmask(TickAttrib, mask))
        end,

  # TICK_SIZE
   2 => function(it, w, ver)

          tickerId::Int,
          ticktype::Int,
          size::Int = it

          w.tickSize(tickerId, tickname(ticktype), size)
        end,

  # ORDER_STATUS
   3 => (it, w, ver) -> w.orderStatus(slurp((Int,String,Float64,Float64,Float64,Int,Int,Float64,Int,String,Float64), it)...),

  # ERR_MSG
   4 => (it, w, ver) -> w.error(slurp((Int,Int,String), it)...),

  # OPEN_ORDER
   5 => function(it, w, ver)

          o = Order()
          c = Contract()

          o.orderId = pop(it)

          slurp!(c, [1:8; 10:12], it)

          slurp!(o, 4:9, it)  # :action through :tif

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

          pop(it)    # Deprecated sharesAllocation

          slurp!(o, (:faGroup,
                     :faMethod,
                     :faPercentage,
                     :faProfile,
                     :modelCode,
                     :goodTillDate,
                     :rule80A,
                     :percentOffset,
                     :settlingFirm,
                     :shortSaleSlot,
                     :designatedLocation,
                     :exemptCode), it)

          slurp!(o, 43:48, it)    # :auctionStrategy through :stockRangeUpper

          slurp!(o, (:displaySize,
                     :blockOrder,
                     :sweepToFill,
                     :allOrNone,
                     :minQty,
                     :ocaType), it)

          pop(it)    # Deprecated eTradeOnly
          pop(it)    # Deprecated firmQuoteOnly
          pop(it)    # Deprecated nbboPriceCap

          slurp!(o, (:parentId,
                     :triggerMethod), it)

          slurp!(o, 51:54, it)    # :volatility through :deltaNeutralAuxPrice

          !isempty(o.deltaNeutralOrderType) && slurp!(o, 55:62, it)  # :deltaNeutralConId through :deltaNeutralDesignatedLocation

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
          n > 0 && (o.smartComboRoutingParams = tagvalue2nt(take(it, 2n)))

          slurp!(o, (:scaleInitLevelSize,
                     :scaleSubsLevelSize,
                     :scalePriceIncrement), it)

          !isnothing(o.scalePriceIncrement) &&
          o.scalePriceIncrement > 0         && slurp!(o, 70:76, it) # scalePriceAdjustValue through scaleRandomPercent

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
            n > 0 && (o.algoParams = tagvalue2nt(take(it, 2n)))
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
                     :usePriceMgmtAlgo), it)

          ver ≥ Client.DURATION && (o.duration = pop(it))

          w.openOrder(o.orderId, c, o, os)
        end,

  # ACCT_VALUE
   6 => (it, w, ver) -> w.updateAccountValue(collect(String, take(it, 4))...),

  # PORTFOLIO_VALUE
   7 => function(it, w, ver)

          c = Contract()

          slurp!(c, [1:7; 9:12], it)

          w.updatePortfolio(c, collect(Float64, take(it, 6))..., slurp(String, it))
        end,

  # ACCT_UPDATE_TIME
   8 => (it, w, ver) -> w.updateAccountTime(slurp(String, it)),

  # NEXT_VALID_ID
   9 => (it, w, ver) -> w.nextValidId(slurp(Int, it)),

  # CONTRACT_DATA
  10 => function(it, w, ver)

          reqId::Int = pop(it)

          cd = ContractDetails()

          slurp!(cd.contract, [2:6; 8; 10; 11], it)

          cd.marketName,
          cd.contract.tradingClass,
          cd.contract.conId,
          cd.minTick,
          cd.mdSizeMultiplier,
          cd.contract.multiplier = it

          slurp!(cd, 4:8, it)
          cd.contract.primaryExchange = pop(it)
          slurp!(cd, 9:17, it)

          n::Int = pop(it)
          n > 0 && (cd.secIdList = tagvalue2nt(take(it, 2n)))

          slurp!(cd, (:aggGroup,
                      :underSymbol,
                      :underSecType,
                      :marketRuleIds,
                      :realExpirationDate,
                      :stockType), it)

          w.contractDetails(reqId, cd)
        end,

  # EXECUTION_DATA
  11 => function(it, w, ver)

          reqId::Int,
          orderId = it

          c = Contract()
          slurp!(c, [1:8; 10:12], it)

          e = Execution(orderId, take(it, 17)...)

          w.execDetails(reqId, c, e)
        end,

  # MARKET_DEPTH
  12 => (it, w, ver) -> w.updateMktDepth(slurp((Int,Int,Int,Int,Float64,Int), it)...),

  # MARKET_DEPTH_L2
  13 => (it, w, ver) -> w.updateMktDepthL2(slurp((Int,Int,String,Int,Int,Float64,Int,Bool), it)...),

  # NEWS_BULLETINS
  14 => (it, w, ver) -> w.updateNewsBulletin(slurp((Int,Int,String,String), it)...),

  # MANAGED_ACCTS
  15 => (it, w, ver) -> w.managedAccounts(slurp(String, it)),

  # RECEIVE_FA
  16 => (it, w, ver) -> w.receiveFA(slurp((FaDataType,String), it)...),

  # HISTORICAL_DATA
  17 => function(it, w, ver)

          reqId::Int = pop(it)

          pop(it) # Ignore startDate
          pop(it) # Ignore endDate

          n::Int = pop(it)

          df = fill_df([String,Float64,Float64,Float64,Float64,Int,Float64,Int],
                       [:time, :open, :high, :low, :close, :volume, :wap, :count],
                       n, it)

          w.historicalData(reqId, df)
        end,

  # BOND_CONTRACT_DATA
  18 => function(it, w, ver)

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
                      :mdSizeMultiplier,
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
          n > 0 && (cd.secIdList = tagvalue2nt(take(it, 2n)))

          cd.aggGroup,
          cd.marketRuleIds = it

          w.bondContractDetails(reqId, cd)
        end,

  # SCANNER_PARAMETERS
  19 => (it, w, ver) -> w.scannerParameters(slurp(String, it)),

  # SCANNER_DATA
  20 => function(it, w, ver)

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
  21 => function(it, w, ver)

          tickerId::Int,
          ticktype::Int = it

          tickAttrib = if ver ≥ Client.PRICE_BASED_VOLATILITY
                         slurp(Int, it)
                       end

          v = collect(Union{Float64,Nothing}, take(it, 8))

          # (impliedVol, optPrice, pvDividend, undPrice) == -1 means NA
          replace!(view(v, [1, 3, 4, 8]), -1 => nothing)

          # (delta, gamma, vega, theta) == -2 means NA
          replace!(view(v, [2, 5, 6, 7]), -2 => nothing)

          w.tickOptionComputation(tickerId, tickname(ticktype), tickAttrib, v...)
        end,

  # TICK_GENERIC
  45 => function(it, w, ver)

          tickerId::Int,
          ticktype::Int,
          value::Float64 = it

          w.tickGeneric(tickerId, tickname(ticktype), value)
        end,

  # TICK_STRING
  46 => function(it, w, ver)

          tickerId::Int,
          ticktype::Int,
          value::String = it

          w.tickString(tickerId, tickname(ticktype), value)
        end,

  # TICK_EFP
  47 => function(it, w, ver)

          tickerId::Int,
          ticktype::Int = it

          w.tickEFP(tickerId, tickname(ticktype), slurp((Float64,String,Float64,Int,String,Float64,Float64), it)...)
        end,

  # CURRENT_TIME
  49 => function(it, w, ver)

          # TODO: Convert to [Zoned]DateTime
          w.currentTime(slurp(Int, it))
        end,

  # REAL_TIME_BARS
  50 => (it, w, ver) -> w.realtimeBar(slurp((Int,Int,Float64,Float64,Float64,Float64,Int,Float64,Int), it)...),

  # FUNDAMENTAL_DATA
  51 => (it, w, ver) -> w.fundamentalData(slurp((Int,String), it)...),

  # CONTRACT_DATA_END
  52 => (it, w, ver) -> w.contractDetailsEnd(slurp(Int, it)),

  # OPEN_ORDER_END
  53 => (it, w, ver) -> w.openOrderEnd(),

  # ACCT_DOWNLOAD_END
  54 => (it, w, ver) -> w.accountDownloadEnd(slurp(String, it)),

  # EXECUTION_DATA_END
  55 => (it, w, ver) -> w.execDetailsEnd(slurp(Int, it)),

  # DELTA_NEUTRAL_VALIDATION
  56 => function(it, w, ver)

          reqId::Int = pop(it)

          w.deltaNeutralValidation(reqId, slurp(DeltaNeutralContract, it))
        end,

  # TICK_SNAPSHOT_END
  57 => (it, w, ver) -> w.tickSnapshotEnd(slurp(Int, it)),

  # MARKET_DATA_TYPE
  58 => (it, w, ver) -> w.marketDataType(slurp((Int,MarketDataType), it)...),

  # COMMISSION_REPORT
  59 => (it, w, ver) -> w.commissionReport(slurp(CommissionReport, it)),

  # POSITION_DATA
  61 => function(it, w, ver)

          account::String = pop(it)

          c = Contract()
          slurp!(c, [1:8; 10:12], it)

          w.position(account, c, collect(Float64, take(it, 2))...)
        end,

  # POSITION_END
  62 => (it, w, ver) -> w.positionEnd(),

  # ACCOUNT_SUMMARY
  63 => function(it, w, ver)

          reqId::Int = pop(it)

          w.accountSummary(reqId, collect(String, take(it, 4))...)
        end,

  # ACCOUNT_SUMMARY_END
  64 => (it, w, ver) -> w.accountSummaryEnd(slurp(Int, it)),

  # VERIFY_MESSAGE_API
  65 => (it, w, ver) -> w.verifyMessageAPI(slurp(String, it)),

  # VERIFY_COMPLETED
  66 => (it, w, ver) -> w.verifyCompleted(slurp((Bool,String), it)...),

  # DISPLAY_GROUP_LIST
  67 => (it, w, ver) -> w.displayGroupList(slurp((Int,String), it)...),

  # DISPLAY_GROUP_UPDATED
  68 => (it, w, ver) -> w.displayGroupUpdated(slurp((Int,String), it)...),

  # VERIFY_AND_AUTH_MESSAGE_API
  69 => (it, w, ver) -> w.verifyAndAuthMessageAPI(collect(String, take(it, 2))...),

  # VERIFY_AND_AUTH_COMPLETED
  70 => (it, w, ver) -> w.verifyAndAuthCompleted(slurp((Bool,String), it)...),

  # POSITION_MULTI
  71 => function(it, w, ver)

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
  72 => (it, w, ver) -> w.positionMultiEnd(slurp(Int, it)),

  # ACCOUNT_UPDATE_MULTI
  73 => (it, w, ver) -> w.accountUpdateMulti(slurp(Int, it), collect(String, take(it, 5))...),

  # ACCOUNT_UPDATE_MULTI_END
  74 => (it, w, ver) -> w.accountUpdateMultiEnd(slurp(Int, it)),

  # SECURITY_DEFINITION_OPTION_PARAMETER
  75 => function(it, w, ver)

          args = slurp((Int,String,Int,String,String), it)

          ne::Int = pop(it)
          expirations = collect(String, take(it, ne))

          ns::Int = pop(it)
          strikes = collect(Float64, take(it, ns))

          w.securityDefinitionOptionalParameter(args..., expirations, strikes)
        end,

  # SECURITY_DEFINITION_OPTION_PARAMETER_END
  76 => (it, w, ver) -> w.securityDefinitionOptionalParameterEnd(slurp(Int, it)),

  # SOFT_DOLLAR_TIERS
  77 => function(it, w, ver)

          reqId::Int,
          n::Int = it

          w.softDollarTiers(reqId, [slurp(SoftDollarTier, it) for _ ∈ 1:n])
        end,

  # FAMILY_CODES
  78 => function(it, w, ver)

          n::Int = pop(it)

          w.familyCodes([slurp(FamilyCode, it) for _ ∈ 1:n])
        end,

  # SYMBOL_SAMPLES
  79 => function(it, w, ver)

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

                  ContractDescription(c, collect(String, take(it, nd)))
                end

          w.symbolSamples(reqId, cd)
        end,

  # MKT_DEPTH_EXCHANGES
  80 => function(it, w, ver)

          n::Int = pop(it)

          df = fill_df([String,String,String,String,Union{Int,Nothing}],
                       [:exchange, :secType, :listingExch, :serviceDataType, :aggGroup],
                       n, it)

          w.mktDepthExchanges(df)
        end,

  # TICK_REQ_PARAMS
  81 => (it, w, ver) -> w.tickReqParams(slurp((Int,Float64,String,Int), it)...),

  # SMART_COMPONENTS
  82 => function(it, w, ver)

          reqId::Int,
          n::Int = it

          df = fill_df([Int,String,String], [:bit, :exchange, :exchangeLetter], n, it)

          w.smartComponents(reqId, df)
        end,

  # NEWS_ARTICLE
  83 => (it, w, ver) -> w.newsArticle(slurp((Int,Int,String), it)...),

  # TICK_NEWS
  84 => function (it, w, ver)

          args = slurp((Int,Int,String,String,String,String), it)

          # TODO: Convert timeStamp to [Zoned]DateTime
          w.tickNews(args...)
        end,

  # NEWS_PROVIDERS
  85 => function(it, w, ver)

          n::Int = pop(it)

          df = fill_df([String,String], [:providerCode, :providerName], n, it)

          w.newsProviders(df)
        end,

  # HISTORICAL_NEWS
  86 => (it, w, ver) -> w.historicalNews(slurp((Int,String,String,String,String), it)...),

  # HISTORICAL_NEWS_END
  87 => (it, w, ver) -> w.historicalNewsEnd(slurp((Int,Bool), it)...),

  # HEAD_TIMESTAMP
  88 => (it, w, ver) -> w.headTimestamp(slurp((Int,String), it)...),

  # HISTOGRAM_DATA
  89 => function(it, w, ver)

          reqId::Int,
          n::Int = it

          df = fill_df([Float64,Int], [:price, :size], n, it)

          w.histogramData(reqId, df)
        end,

  # HISTORICAL_DATA_UPDATE
  90 => function(it, w, ver)

          reqId::Int = pop(it)

          bar = NamedTuple{(:count,
                            :time,
                            :open,
                            :close,
                            :high,
                            :low,
                            :wap,
                            :volume)}(slurp((Int,String,Float64,Float64,Float64,Float64,Float64,Int), it))

          w.historicalDataUpdate(reqId, bar)
        end,

  # REROUTE_MKT_DATA_REQ
  91 => (it, w, ver) -> w.rerouteMktDataReq(slurp((Int,Int,String), it)...),

  # REROUTE_MKT_DEPTH_REQ
  92 => (it, w, ver) -> w.rerouteMktDepthReq(slurp((Int,Int,String), it)...),

  # MARKET_RULE
  93 => function(it, w, ver)

          marketRuleId::Int,
          n::Int = it

          df = fill_df([Float64,Float64], [:lowEdge, :increment], n, it)

          w.marketRule(marketRuleId, df)
        end,

  # PNL
  94 => function(it, w, ver)

          reqId::Int,
          dailyPnL::Float64,
          unrealizedPnL::Float64,
          realizedPnL::Float64 = it

          w.pnl(reqId, dailyPnL, unrealizedPnL, realizedPnL)
        end,

  # PNL_SINGLE
  95 => function(it, w, ver)

          reqId::Int,
          pos::Int,
          dailyPnL::Float64,
          unrealizedPnL::Union{Float64,Nothing},
          realizedPnL::Union{Float64,Nothing},
          value::Float64 = it

          w.pnlSingle(reqId, pos, dailyPnL, unrealizedPnL, realizedPnL, value)

        end,

  # HISTORICAL_TICKS
  96 => function(it, w, ver)

          reqId::Int,
          n::Int = it

          df = fill_df([Int,Int,Float64,Int], [:time, :ignore, :price, :size], n, it)

          select!(df, Not(:ignore))

          # TODO: Convert df[:time] to [Zoned]DateTime

          done::Bool = pop(it)

          w.historicalTicks(reqId, df, done)
        end,

  # HISTORICAL_TICKS_BID_ASK
  97 => function(it, w, ver)

          reqId::Int,
          n::Int = it

          df = fill_df([Int,Int,Float64,Float64,Int,Int], [:time, :mask, :priceBid, :priceAsk, :sizeBid, :sizeAsk], n, it)

          # TODO: Convert df[:time] to [Zoned]DateTime
          # TODO: Unmask df[:mask]

          done::Bool = pop(it)

          w.historicalTicksBidAsk(reqId, df, done)
        end,

  # HISTORICAL_TICKS_LAST
  98 => function(it, w, ver)

          reqId::Int,
          n::Int = it

          df = fill_df([Int,Int,Float64,Int,String,String], [:time, :mask, :price, :size, :exchange, :specialConditions], n, it)

          # TODO: Convert df[:time] to [Zoned]DateTime
          # TODO: Unmask df[:mask]

          done::Bool = pop(it)

          w.historicalTicksLast(reqId, df, done)
        end,

  # TICK_BY_TICK
  99 => function(it, w, ver)

          reqId::Int,
          ticktype::Int,
          time::Int = it

          mask::Int = 0  # To avoid "multiple type declarations" error

          if ticktype ∈ (1, 2)

            price::Float64,
            size::Int,
            mask,
            exchange::String,
            specialConditions::String = it

            w.tickByTickAllLast(reqId, ticktype, time, price, size, unmask(TickAttribLast, mask), exchange, specialConditions)

          elseif ticktype == 3

            bidPrice::Float64,
            askPrice::Float64,
            bidSize::Int,
            askSize::Int,
            mask = it

            w.tickByTickBidAsk(reqId, time, bidPrice, askPrice, bidSize, askSize, unmask(TickAttribBidAsk, mask))

          elseif ticktype == 4

            w.tickByTickMidPoint(reqId, time, slurp(Float64, it))

          else
            @warn "TICK_BY_TICK: Unknown ticktype" T=ticktype
          end
        end,

  # ORDER_BOUND
 100 => (it, w, ver) -> w.orderBound(collect(Int, take(it, 3))...),

  # COMPLETED_ORDER
 101 => function(it, w, ver)

          o = Order()
          c = Contract()

          slurp!(c, [1:8; 10:12], it)

          slurp!(o, 4:9, it)  # :action through :tif

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
                     :faProfile,
                     :modelCode,
                     :goodTillDate,
                     :rule80A,
                     :percentOffset,
                     :settlingFirm,
                     :shortSaleSlot,
                     :designatedLocation,
                     :exemptCode), it)

          slurp!(o, 44:48, it)    # :startingPrice through :stockRangeUpper

          slurp!(o, (:displaySize,
                     :sweepToFill,
                     :allOrNone,
                     :minQty,
                     :ocaType,
                     :triggerMethod), it)

          slurp!(o, 51:54, it)    # :volatility through :deltaNeutralAuxPrice

          !isempty(o.deltaNeutralOrderType) && slurp!(o, [55; 60:62], it)  # :deltaNeutralConId through :deltaNeutralDesignatedLocation

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
          n > 0 && (o.smartComboRoutingParams = tagvalue2nt(take(it, 2n)))

          slurp!(o, (:scaleInitLevelSize,
                     :scaleSubsLevelSize,
                     :scalePriceIncrement), it)

          !isnothing(o.scalePriceIncrement) &&
          o.scalePriceIncrement > 0         && slurp!(o, 70:76, it) # scalePriceAdjustValue through scaleRandomPercent

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
            n > 0 && (o.algoParams = tagvalue2nt(take(it, 2n)))
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

          slurp!(o, 119:126, it)    # :autoCancelDate through :parentPermId

          os = OrderState(ostatus, fill(ns, 9)..., fill(nothing, 3)..., ns, ns, take(it, 2)...)

          w.completedOrder(c, o, os)
         end,

  # COMPLETED_ORDERS_END
 102 => (it, w, ver) -> w.completedOrdersEnd(),

  # REPLACE_FA_END
 103 => (it, w, ver) -> w.replaceFAEnd(slurp((Int,String), it)...)

)
