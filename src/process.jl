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
       ...faDataType,
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
  Some utility functions

"""
slurp(::Type{T}, it) where {T<:Union{Bool,Int,Enum{Int32},Float64,String}} = convert(T, pop(it))

slurp(::Type{T}, it) where {T} = T(take(it, fieldcount(T))...)

slurp(t, it) = convert.(t, take(it, length(t)))

slurp!(x::T, idx, it) where {T} = setfield!.(Ref(x), idx, slurp(fieldtype.(T, idx), it))


"""
  Convert a String[] into a NamedTuple() like this:

  ["tag1", "value1", "tag2", "value2", ...] -> (tag1="value1", tag2="value2", ...)

"""
function tagvalue2nt(x)

  @assert iseven(length(x))

  s = collect(String, x)

  t = Tuple(Symbol.(s[1:2:end]))
  v = Tuple(s[2:2:end])

  NamedTuple{t}(v)
end


function unmask(T::Type{NamedTuple{M,NTuple{N,Bool}}}, mask::Int) where {M} where {N}

  a = digits(Bool, mask, base=2, pad=N)

  length(a) == N || @warn "unmask(): wrong attribs" T=T mask=mask

  T(a)
end


function fill_df(eltypes, names, n, it)

  dt = DataFrame(eltypes, names, n)

  nr, nc = size(dt)

  for r ∈ 1:nr, c ∈ 1:nc
    dt[r, c] = pop(it)
  end

  dt
end


"""
  Collection of parsers indexed by message ID

"""
const process = Dict{Int,Function}(

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
   3 => function(it, w, ver)

          args = slurp((Int,String,Float64,Float64,Float64,Int,Int,Float64,Int,String), it)

          mktCapPrice = ver ≥ Client.MARKET_CAP_PRICE ? slurp(Float64, it) : nothing

          w.orderStatus(args..., mktCapPrice)
        end,

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

          pop(it)   # Ignore :sharesAllocation

          slurp!(o, (:faGroup,
                     :faMethod,
                     :faPercentage,
                     :faProfile), it)

          ver ≥ Client.MODELS_SUPPORT && (o.modelCode = pop(it))

          slurp!(o, (:goodTillDate,
                     :rule80A,
                     :percentOffset,
                     :settlingFirm,
                     :shortSaleSlot,
                     :designatedLocation,
                     :exemptCode), it)

          slurp!(o, 46:51, it)    # :auctionStrategy through :stockRangeUpper

          slurp!(o, (:displaySize,
                     :blockOrder,
                     :sweepToFill,
                     :allOrNone,
                     :minQty,
                     :ocaType,
                     :eTradeOnly,
                     :firmQuoteOnly,
                     :nbboPriceCap,
                     :parentId,
                     :triggerMethod), it)

          slurp!(o, 54:57, it)    # :volatility" through :deltaNeutralAuxPrice"

          !isempty(o.deltaNeutralOrderType) && slurp!(o, 58:65, it)  # :deltaNeutralConId through :deltaNeutralDesignatedLocation

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
          o.scalePriceIncrement > 0.0       && slurp!(o, 73:79, it) # scalePriceAdjustValue through scaleRandomPercent

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

          os = ver ≥ Client.WHAT_IF_EXT_FIELDS ? OrderState(take(it, 15)..., ns, ns) :
                                                 OrderState(pop(it), fill(ns, 6)..., take(it, 8)..., ns, ns)

          o.randomizeSize,
          o.randomizePrice = it

          if ver ≥ Client.PEGGED_TO_BENCHMARK

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
          end

          ver ≥ Client.SOFT_DOLLAR_TIER &&
                (o.softDollarTier = slurp(SoftDollarTier, it))

          ver ≥ Client.CASH_QTY && (o.cashQty = pop(it))

          ver ≥ Client.AUTO_PRICE_FOR_HEDGE && (o.dontUseAutoPriceForHedge = pop(it))

          ver ≥ Client.ORDER_CONTAINER && (o.isOmsContainer = pop(it))

          ver ≥ Client.D_PEG_ORDERS && (o.discretionaryUpToLimitPrice = pop(it))

          ver ≥ Client.PRICE_MGMT_ALGO && (o.usePriceMgmtAlgo = pop(it))

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
          cd.minTick = it

          ver ≥ Client.MD_SIZE_MULTIPLIER && (cd.mdSizeMultiplier = pop(it))

          cd.contract.multiplier = pop(it)
          slurp!(cd, 4:8, it)
          cd.contract.primaryExchange = pop(it)
          slurp!(cd, 9:17, it)

          n::Int = pop(it)
          n > 0 && (cd.secIdList = tagvalue2nt(take(it, 2n)))

          ver ≥ Client.AGG_GROUP && (cd.aggGroup = pop(it))

          if ver ≥ Client.UNDERLYING_INFO
            cd.underSymbol,
            cd.underSecType = it
          end

          ver ≥ Client.MARKET_RULES && (cd.marketRuleIds = pop(it))

          ver ≥ Client.REAL_EXPIRATION_DATE && (cd.realExpirationDate = pop(it))

          w.contractDetails(reqId, cd)
        end,

  # EXECUTION_DATA
  11 => function(it, w, ver)

          reqId::Int,
          orderId = it

          c = Contract()
          slurp!(c, [1:8; 10:12], it)

          args = collect(take(it, 15))   # Must materialize

          modelCode = ver ≥ Client.MODELS_SUPPORT ? pop(it) : ns

          lastLiquidity = ver ≥ Client.LAST_LIQUIDITY ? pop(it) : 0

          e = Execution(orderId, args..., modelCode, lastLiquidity)

          w.execDetails(reqId, c, e)
        end,

  # MARKET_DEPTH
  12 => (it, w, ver) -> w.updateMktDepth(slurp((Int,Int,Int,Int,Float64,Int), it)...),

  # MARKET_DEPTH_L2
  13 => function(it, w, ver)

          args = slurp((Int,Int,String,Int,Int,Float64,Int), it)

          isSmartDepth = ver ≥ Client.SMART_DEPTH ? slurp(Bool, it) : false

          w.updateMktDepthL2(args..., isSmartDepth)
        end,

  # NEWS_BULLETINS
  14 => (it, w, ver) -> w.updateNewsBulletin(slurp((Int,Int,String,String), it)...),

  # MANAGED_ACCTS
  15 => (it, w, ver) -> w.managedAccounts(slurp(String, it)),

  # RECEIVE_FA
  16 => (it, w, ver) -> w.receiveFA(slurp((faDataType,String), it)...),

  # HISTORICAL_DATA
  17 => function(it, w, ver)

          reqId::Int = pop(it)

          # Ignore startDate, endDate
          collect(take(it, 2))   # Must materialize

          n::Int = pop(it)

          dt = if ver < Client.SYNT_REALTIME_BARS

                tmp = fill_df([String,Float64,Float64,Float64,Float64,Int,Float64,String,Int],
                              [:time, :open, :high, :low, :close, :volume, :wap, :hasGaps, :count],
                              n, it)

                # Drop "hasGaps"
                deletecols!(tmp, :hasGaps)

                tmp
              else

                fill_df([String,Float64,Float64,Float64,Float64,Int,Float64,Int],
                        [:time, :open, :high, :low, :close, :volume, :wap, :count],
                        n, it)
              end

          w.historicalData(reqId, dt)
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
          cd.contract.conId,
          cd.minTick = it

          ver ≥ Client.MD_SIZE_MULTIPLIER && (cd.mdSizeMultiplier = pop(it))

          slurp!(cd, (:orderTypes,
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

          ver ≥ Client.AGG_GROUP && (cd.aggGroup = pop(it))

          ver ≥ Client.MARKET_RULES && (cd.marketRuleIds = pop(it))

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

          v = collect(Union{Float64,Nothing}, take(it, 8))

          # (impliedVol, optPrice, pvDividend, undPrice) == -1 means NA
          v[filter(i -> v[i] == -1, [1, 3, 4, 8])] .= nothing

          # (delta, gamma, vega, theta) == -2 means NA
          v[filter(i -> v[i] == -2, [2, 5, 6, 7])] .= nothing


          w.tickOptionComputation(tickerId, tickname(ticktype), v...)
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

          f = function()

                c = Contract()

                slurp!(c, (:conId,
                           :symbol,
                           :secType,
                           :primaryExchange,
                           :currency), it)

                nd::Int = pop(it)

                ContractDescription(c, collect(String, take(it, nd)))
          end

          cd = [f() for _ ∈ 1:n]

          w.symbolSamples(reqId, cd)
        end,

  # MKT_DEPTH_EXCHANGES
  80 => function(it, w, ver)

          n::Int = pop(it)

          dt = if ver ≥ Client.SERVICE_DATA_TYPE

                 fill_df([String,String,String,String,Union{Int,Nothing}], [:exchange, :secType, :listingExch, :serviceDataType, :aggGroup], n, it)

               else

                 tmp = fill_df([String,String,Bool], [:exchange, :secType, :isL2], n, it)

                 tmp.serviceDataType = ifelse.(tmp.isL2, "Deep2", "Deep")

                 deletecols!(tmp, :isL2)

                 tmp
                end

          w.mktDepthExchanges(dt)
        end,

  # TICK_REQ_PARAMS
  81 => (it, w, ver) -> w.tickReqParams(slurp((Int,Float64,String,Int), it)...),

  # SMART_COMPONENTS
  82 => function(it, w, ver)

          reqId::Int,
          n::Int = it

          dt = fill_df([Int,String,String], [:bit, :exchange, :exchangeLetter], n, it)

          w.smartComponents(reqId, dt)
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

          dt = fill_df([String,String], [:providerCode, :providerName], n, it)

          w.newsProviders(dt)
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

          dt = fill_df([Float64,Int], [:price, :size], n, it)

          w.histogramData(reqId, dt)
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

          dt = fill_df([Float64,Float64], [:lowEdge, :increment], n, it)

          w.marketRule(marketRuleId, dt)
        end,

  # PNL
  94 => function(it, w, ver)

          reqId::Int,
          dailyPnL::Float64 = it

          unrealizedPnL = realizedPnL = nothing

          ver ≥ Client.UNREALIZED_PNL && (unrealizedPnL = slurp(Float64, it))

          ver ≥ Client.REALIZED_PNL && (realizedPnL = slurp(Float64, it))

          w.pnl(reqId, dailyPnL, unrealizedPnL, realizedPnL)
        end,

  # PNL_SINGLE
  95 => function(it, w, ver)

          reqId::Int,
          pos::Int,
          dailyPnL::Float64 = it

          unrealizedPnL = realizedPnL = nothing

          ver ≥ Client.UNREALIZED_PNL && (unrealizedPnL = slurp(Float64, it))

          ver ≥ Client.REALIZED_PNL && (realizedPnL = slurp(Float64, it))

          value::Float64 = pop(it)

          w.pnlSingle(reqId, pos, dailyPnL, unrealizedPnL, realizedPnL, value)

        end,

  # HISTORICAL_TICKS
  96 => function(it, w, ver)

          reqId::Int,
          n::Int = it

          dt = fill_df([Int,Int,Float64,Int], [:time, :ignore, :price, :size], n, it)

          deletecols!(dt, :ignore)

          # TODO: Convert dt[:time] to [Zoned]DateTime

          done::Bool = pop(it)

          w.historicalTicks(reqId, dt, done)
        end,

  # HISTORICAL_TICKS_BID_ASK
  97 => function(it, w, ver)

          reqId::Int,
          n::Int = it

          dt = fill_df([Int,Int,Float64,Float64,Int,Int], [:time, :mask, :priceBid, :priceAsk, :sizeBid, :sizeAsk], n, it)

          # TODO: Convert dt[:time] to [Zoned]DateTime
          # TODO: Unmask dt[:mask]

          done::Bool = pop(it)

          w.historicalTicksBidAsk(reqId, dt, done)
        end,

  # HISTORICAL_TICKS_LAST
  98 => function(it, w, ver)

          reqId::Int,
          n::Int = it

          dt = fill_df([Int,Int,Float64,Int,String,String], [:time, :mask, :price, :size, :exchange, :specialConditions], n, it)

          # TODO: Convert dt[:time] to [Zoned]DateTime
          # TODO: Unmask dt[:mask]

          done::Bool = pop(it)

          w.historicalTicksLast(reqId, dt, done)
        end,

  # TICK_BY_TICK
  99 => function(it, w, ver)

          reqId::Int,
          ticktype::Int,
          time::Int = it

          mask::Int = 0  # To avoid "multiple type declarations" error

          if ticktype ∈ [1, 2]

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
                     :faProfile), it)

          ver ≥ Client.MODELS_SUPPORT && (o.modelCode = pop(it))

          slurp!(o, (:goodTillDate,
                     :rule80A,
                     :percentOffset,
                     :settlingFirm,
                     :shortSaleSlot,
                     :designatedLocation,
                     :exemptCode), it)

          slurp!(o, 47:51, it)    # :startingPrice through :stockRangeUpper

          slurp!(o, (:displaySize,
                     :sweepToFill,
                     :allOrNone,
                     :minQty,
                     :ocaType,
                     :triggerMethod), it)

          slurp!(o, 54:57, it)    # :volatility" through :deltaNeutralAuxPrice"

          !isempty(o.deltaNeutralOrderType) && slurp!(o, [58; 63:65], it)  # :deltaNeutralConId through :deltaNeutralDesignatedLocation

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
          o.scalePriceIncrement > 0.0       && slurp!(o, 73:79, it) # scalePriceAdjustValue through scaleRandomPercent

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

          if ver ≥ Client.PEGGED_TO_BENCHMARK

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

          end

          slurp!(o, (:trailStopPrice,
                     :lmtPriceOffset), it)

          ver ≥ Client.CASH_QTY && (o.cashQty = pop(it))

          ver ≥ Client.AUTO_PRICE_FOR_HEDGE && (o.dontUseAutoPriceForHedge = pop(it))

          ver ≥ Client.ORDER_CONTAINER && (o.isOmsContainer = pop(it))

          slurp!(o, 122:129, it)    # :autoCancelDate through :parentPermId

          os = OrderState(ostatus, fill(ns, 9)..., fill(nothing, 3)..., ns, ns, take(it, 2)...)

          w.completedOrder(c, o, os)
         end,

  # COMPLETED_ORDERS_END
 102 => (it, w, ver) -> w.completedOrdersEnd()
)
