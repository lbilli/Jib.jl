struct Wrapper
  tickPrice::Function
  tickSize::Function
  tickOptionComputation::Function
  tickGeneric::Function
  tickString::Function
  tickEFP::Function
  orderStatus::Function
  openOrder::Function
  openOrderEnd::Function
#  winError::Function
#  connectionClosed::Function
  updateAccountValue::Function
  updatePortfolio::Function
  updateAccountTime::Function
  accountDownloadEnd::Function
  nextValidId::Function
  contractDetails::Function
  bondContractDetails::Function
  contractDetailsEnd::Function
  execDetails::Function
  execDetailsEnd::Function
  error::Function
  updateMktDepth::Function
  updateMktDepthL2::Function
  updateNewsBulletin::Function
  managedAccounts::Function
  receiveFA::Function
  historicalData::Function
  scannerParameters::Function
  scannerData::Function
  realtimeBar::Function
  currentTime::Function
  fundamentalData::Function
  deltaNeutralValidation::Function
  tickSnapshotEnd::Function
  marketDataType::Function
  commissionReport::Function
  position::Function
  positionEnd::Function
  accountSummary::Function
  accountSummaryEnd::Function
  verifyMessageAPI::Function
  verifyCompleted::Function
  displayGroupList::Function
  displayGroupUpdated::Function
  verifyAndAuthMessageAPI::Function
  verifyAndAuthCompleted::Function
#  connectAck::Function
  positionMulti::Function
  positionMultiEnd::Function
  accountUpdateMulti::Function
  accountUpdateMultiEnd::Function
  securityDefinitionOptionalParameter::Function
  securityDefinitionOptionalParameterEnd::Function
  softDollarTiers::Function
  familyCodes::Function
  symbolSamples::Function
  mktDepthExchanges::Function
  tickNews::Function
  smartComponents::Function
  tickReqParams::Function
  newsProviders::Function
  newsArticle::Function
  historicalNews::Function
  historicalNewsEnd::Function
  headTimestamp::Function
  histogramData::Function
  historicalDataUpdate::Function
  rerouteMktDataReq::Function
  rerouteMktDepthReq::Function
  marketRule::Function
  pnl::Function
  pnlSingle::Function
  historicalTicks::Function
  historicalTicksBidAsk::Function
  historicalTicksLast::Function
  tickByTickAllLast::Function
  tickByTickBidAsk::Function
  tickByTickMidPoint::Function
  orderBound::Function
  completedOrder::Function
  completedOrdersEnd::Function
end
function Wrapper(; kw...)

  default = (_...) -> println("Default Implementation")

  args = (get(kw, a, default) for a ∈ fieldnames(Wrapper))

  Wrapper(args...)
end


function simple_wrap()

  d = Dict{Symbol,Any}()

  w = Wrapper(

    tickPrice= (tickerId::Int, field::String, price::Float64, size::Int, attrib::TickAttrib) ->
                 println("Price: $tickerId $field $price $size $attrib"),

    tickSize= (tickerId::Int, field::String, size::Int) -> println("Size: $tickerId $field $size"),

    tickOptionComputation= function(tickerId::Int, tickType::String, tickAttrib::Union{Int,Nothing}, impliedVol::Union{Float64,Nothing}, delta::Union{Float64,Nothing}, optPrice::Union{Float64,Nothing}, pvDividend::Union{Float64,Nothing}, gamma::Union{Float64,Nothing}, vega::Union{Float64,Nothing}, theta::Union{Float64,Nothing}, undPrice::Union{Float64,Nothing})
                             d[:option] = (tickType, tickAttrib, impliedVol, delta, optPrice, pvDividend, gamma, vega, theta, undPrice)
                             println("Option: $tickerId $tickType")
                           end,

    tickGeneric= (tickerId::Int, tickType::String, value::Float64) ->
                   println("Generic: $tickerId $tickType $value"),

    tickString= (tickerId::Int, tickType::String, value::String) ->
                  println("String: $tickerId $tickType $value"),

    orderStatus= function(orderId::Int, status::String, filled::Float64, remaining::Float64, avgFillPrice::Float64, permId::Int, parentId::Int, lastFillPrice::Float64, clientId::Int, whyHeld::String, mktCapPrice::Union{Float64,Nothing})
                   d[:orderstatus] = (orderId=       orderId,
                                      status=        status,
                                      filled=        filled,
                                      remaining=     remaining,
                                      avgFillPrice=  avgFillPrice,
                                      permId=        permId,
                                      lastFillPrice= lastFillPrice,
                                      clientId=      clientId,
                                      whyHeld=       whyHeld,
                                      mktCapPrice=   mktCapPrice)
                   println("OrderStatus: $orderId $status")
                 end,

    openOrder= function(orderId::Int, contract::Contract, order::Order, orderstate::OrderState)
                 d[:order_contract] = contract
                 d[:order] = order
                 d[:orderstate] = orderstate
                 println("OpenOrder: $orderId $(orderstate.status)")
              end,

    openOrderEnd= () -> println("OpenOrderEnd."),

    updateAccountValue= (key::String, val::String, currency::String, accountName::String) ->
                          println("AccountValue: $key $val $currency $accountName"),

    updatePortfolio= (contract::Contract, position::Float64, marketPrice::Float64, marketValue::Float64, averageCost::Float64, unrealizedPNL::Float64, realizedPNL::Float64, accountName::String) ->
                       println("Portfolio:  $(contract.symbol) $position $marketPrice $marketValue $averageCost $unrealizedPNL $realizedPNL $accountName"),

    updateAccountTime= (timeStamp::String) -> println("AccountTime: $timeStamp"),

    accountDownloadEnd= (accountName::String) -> println("AccountDownloadEnd: $accountName"),

    nextValidId= (orderId::Int) -> d[:nextId] = orderId,

    contractDetails = function(reqId::Int, contractDetails::ContractDetails)
                        d[:cd] = contractDetails
                        println("ContractDetails: $reqId ", contractDetails.contract.conId)
                      end,

    contractDetailsEnd= (reqId::Int) -> println("ContractDetailsEnd: $reqId"),

    execDetails= function(reqId::Int, contract::Contract, execution::Execution)
                    d[:ex_con] = contract
                    d[:execution] = execution
                    println("ExecDetails: $reqId")
                 end,

    execDetailsEnd= (reqId::Int) -> println("ExecDetailsEnd: $reqId"),

    error= (id::Union{Int,Nothing}, errorCode::Union{Int,Nothing}, errorString::String) ->
                     println("Error: ",
                             something(id, "NA"), " ",
                             something(errorCode, "NA"), " ",
                             errorString),

    updateMktDepth= (id::Int, position::Int, operation::Int, side::Int, price::Float64, size::Int) ->
                      println("MktDepth: $id $position $operation $side $price $size"),

    updateMktDepthL2= (id::Int, position::Int, marketMaker::String, operation::Int, side::Int, price::Float64, size::Int, isSmartDepth::Bool) ->
                        println("MktDepthL2: $id $position $marketMaker $operation $side $price $size $isSmartDepth"),

    updateNewsBulletin= function(msgId::Int, msgType::Int, newsMessage::String, originExch::String)
                          d[:newsbulletin] = newsMessage
                          println("NewsBulletin: $msgId $msgType $originExch")
                          println(newsMessage)
                        end,

    managedAccounts= (accountsList::String) -> d[:accounts] = accountsList,

    receiveFA= function(pFaDataType::faDataType, cxml::String)
                 d[:fa] = cxml
                 println("ReceiveFA: $pFaDataType")
               end,

    historicalData= function(reqId::Int, bar::DataFrame)
                      d[:history] = bar
                      println("HistoricalData: $reqId $(size(bar))")
                    end,

    scannerParameters= function(xml::String)
                        d[:scannerparam] = xml
                        println("ScannerParameters.")
                       end,

    scannerData= function(reqId::Int, rank::Vector{Int}, contractDetails::Vector{ContractDetails}, distance::Vector{String}, benchmark::Vector{String}, projection::Vector{String}, legsStr::Vector{String})
                   d[:scannerdata] = (rank=       rank,
                                      cd=         contractDetails,
                                      distance=   distance,
                                      benchmark=  benchmark,
                                      projection= projection,
                                      legsStr=    legsStr)
                   println("ScannerData: $reqId")
                 end,

    realtimeBar= (reqId::Int, time::Int, open::Float64, high::Float64, low::Float64, close::Float64, volume::Int, wap::Float64, count::Int) ->
                   println("RealTimeBar: $reqId $time $open $high, $low $close $volume $wap $count"),

    currentTime= (time::Int) -> println("CurrentTime: $time"),

    fundamentalData= function(reqId::Int, data::String)
                       d[:fundamental] = data
                       println("FundamentalData: $reqId")
                     end,

    tickSnapshotEnd= (reqId::Int) -> println("TickSnapshotEnd: $reqId"),

    marketDataType= (reqId::Int, marketDataType::MarketDataType) -> println("MarketDataType: $reqId $marketDataType"),

    commissionReport= function(commissionReport::CommissionReport)
                        d[:commission] = commissionReport
                        println("CommissionReport.")
                      end,

    position= (account::String, contract::Contract, position::Float64, avgCost::Float64) ->
                println("Position: $account $(contract.symbol) $position $avgCost"),

    positionEnd= () -> println("PositionEnd."),

    accountSummary= (reqId::Int, account::String, tag::String, value::String, currency::String) -> println("AccountSummary: $reqId $account $tag $value $currency"),

    accountSummaryEnd= (reqId::Int) -> println("AccountSummaryEnd: $reqId"),

    displayGroupList= (reqId::Int, groups::String) -> println("DisplayGroupList: $reqId $groups"),

    displayGroupUpdated= (reqId::Int, contractInfo::String) -> println("DisplayGroupUpdated: $reqId $contractInfo"),

    positionMulti= (reqId::Int, account::String, modelCode::String, contract::Contract, position::Float64, avgCost::Float64) ->
                     println("PositionMulti: $reqId $account $modelCode $(contract.symbol) $position $avgCost"),

    positionMultiEnd= (reqId::Int) -> println("PositionMultiEnd $reqId"),

    accountUpdateMulti= (reqId::Int, account::String, modelCode::String, key::String, value::String, currency::String) -> println("AccountUpdateMulti: $reqId $account, $modelCode $key=$value $currency"),

    accountUpdateMultiEnd= (reqId::Int) -> println("AccountUpdateMultiEnd: $reqId"),

    securityDefinitionOptionalParameter= function(reqId::Int, exchange::String, underlyingConId::Int, tradingClass::String, multiplier::String, expirations::Vector{String}, strikes::Vector{Float64})
                                           d[:sdop] = (e= expirations,
                                                       s= strikes)
                                           println("SDOP: $reqId $exchange $underlyingConId $tradingClass $multiplier $(length(expirations)) $(length(strikes))")
                                         end,

    securityDefinitionOptionalParameterEnd= (reqId::Int) -> println("SDOPEnd: $reqId"),

    softDollarTiers= function(reqId::Int, tiers::Vector{SoftDollarTier})
                       d[:softdollar] = tiers
                       println("SoftDollarTiers: $reqId $(length(tiers))")
                     end,

    familyCodes= function(familyCodes::Vector{FamilyCode})
                   d[:familycodes] = familyCodes
                   println("FamilyCodes: $(length(familyCodes))")
                 end,

    symbolSamples= function(reqId::Int, contractDescriptions::Vector{ContractDescription})
                     d[:symbolsamples] = contractDescriptions
                     println("SymbolSamples: $reqId")
                   end,

    mktDepthExchanges= function(depthMktDataDescriptions::DataFrame)
                        d[:mktdepthexchanges] = depthMktDataDescriptions
                        println("MktDepthExchanges.")
                      end,

    tickNews= (tickerId::Int, timeStamp::Int, providerCode::String, articleId::String, headline::String, extraData::String) ->
                println("TickNews: $tickerId $timeStamp $providerCode $articleId $headline $extraData"),

    smartComponents= function(reqId::Int, theMap::DataFrame)
                       d[:smartcomponents] = theMap
                       println("SmartComponents: $reqId $(size(theMap))")
                     end,

    tickReqParams= (tickerId::Int, minTick::Union{Float64,Nothing}, bboExchange::String, snapshotPermissions::Int) ->
                     println("TickReqParams: $tickerId ",
                             something(minTick, "NA"),
                             " $bboExchange $snapshotPermissions"),

    newsProviders= function(newsProviders::DataFrame)
                     d[:newsproviders] = newsProviders
                     println("NewsProviders.")
                   end,

    newsArticle= function(requestId::Int, articleType::Int, articleText::String)
                   d[:newsarticle] = articleText
                   println("NewsArticle: $requestId $articleType")
                 end,

    headTimestamp= (reqId::Int, headTimestamp::String) -> println("HeadTimestamp: $reqId $headTimestamp"),

    histogramData= function(reqId::Int, data::DataFrame)
                    d[:histogram] = data
                    println("HistogramData: $reqId")
                  end,

    historicalDataUpdate= (reqId::Int, bar::NamedTuple) ->
                            println("HistoricalDataUpdate: $reqId $bar"),

    marketRule= function(marketRuleId::Int, priceIncrements::DataFrame)
                  d[:marketrule] = priceIncrements
                  println("MarketRule: $marketRuleId")
                end,

    pnl= (reqId::Int, dailyPnL::Float64, unrealizedPnL::Float64, realizedPnL::Float64) ->
           println("PnL: $reqId $dailyPnL $unrealizedPnL $realizedPnL"),

    pnlSingle= (reqId::Int, pos::Int, dailyPnL::Float64, unrealizedPnL::Union{Float64,Nothing}, realizedPnL::Union{Float64,Nothing}, value::Float64) ->
                 println("PnLSingle: $reqId $pos $dailyPnL ",
                         something(unrealizedPnL, "NA"), " ",
                         something(realizedPnL, "NA"),   " ",
                         value),

    historicalTicks= function(reqId::Int, ticks::DataFrame, done::Bool)
                       d[:historyticks] = ticks
                       println("HistoricalTicks: $reqId $done")
                     end,

    historicalTicksBidAsk= function(reqId::Int, ticks::DataFrame, done::Bool)
                             d[:historyticksbidask] = ticks
                             println("HistoricalTicksBidAsk: $reqId $done")
                           end,

    historicalTicksLast= function(reqId::Int, ticks::DataFrame, done::Bool)
                           d[:historytickslast] = ticks
                           println("HistoricalTicksLast: $reqId $done")
                         end,

    tickByTickAllLast= (reqId::Int, tickType::Int, time::Int, price::Float64, size::Int, attribs::TickAttribLast, exchange::String, specialConditions::String) ->
                         println("TickByTickAllLast: $reqId $tickType $time $price $size $attribs $exchange $specialConditions"),

    tickByTickBidAsk= (reqId::Int, time::Int, bidPrice::Float64, askPrice::Float64, bidSize::Int, askSize::Int, attribs::TickAttribBidAsk) ->
                        println("TickByTickBidAsk: $reqId $time $bidPrice $askPrice $bidSize $askSize $attribs"),

    tickByTickMidPoint= (reqId::Int, time::Int, midPoint::Float64) ->
                          println("TickByTickMidPoint: $reqId $time $midPoint"),

    orderBound= (orderId::Int, apiClientId::Int, apiOrderId::Int) ->
                  println("OrderBound: $orderId $apiClientId $apiOrderId"),

    completedOrder= function(contract::Contract, order::Order, orderState::OrderState)
                      d[:completed_contract] = contract
                      d[:completed] = order
                      d[:completed_state] = orderState
                 println("CompletedOrder: $(contract.symbol) $(orderState.status)")
              end,

    completedOrdersEnd= () -> println("CompletedOrdersEnd."),
  )

  d, w
end
