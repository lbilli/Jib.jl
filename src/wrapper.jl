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
  replaceFAEnd::Function
  wshMetaData::Function
  wshEventData::Function
end
function Wrapper(; kw...)

  function default(field::Symbol)
    return (_...) -> println("$field default implementation")
  end

  args = (get(kw, a, default(a)) for a ∈ fieldnames(Wrapper))

  Wrapper(args...)
end


function simple_wrap()

  d = Dict{Symbol,Any}()

  w = Wrapper(

    tickPrice= (tickerId::Int, field::String, price::Float64, size::Float64, attrib::TickAttrib) ->
                 println("tickPrice: $tickerId $field $price $size $attrib"),

    tickSize= (tickerId::Int, field::String, size::Float64) -> println("tickSize: $tickerId $field $size"),

    tickOptionComputation= function(tickerId::Int, tickType::String, tickAttrib::Union{Int,Nothing}, impliedVol::Union{Float64,Nothing}, delta::Union{Float64,Nothing}, optPrice::Union{Float64,Nothing}, pvDividend::Union{Float64,Nothing}, gamma::Union{Float64,Nothing}, vega::Union{Float64,Nothing}, theta::Union{Float64,Nothing}, undPrice::Union{Float64,Nothing})
                             d[:option] = (tickType, tickAttrib, impliedVol, delta, optPrice, pvDividend, gamma, vega, theta, undPrice)
                             println("tickOption: $tickerId $tickType")
                           end,

    tickGeneric= (tickerId::Int, tickType::String, value::Float64) ->
                   println("tickGeneric: $tickerId $tickType $value"),

    tickString= (tickerId::Int, tickType::String, value::String) ->
                  println("tickString: $tickerId $tickType $value"),

    orderStatus= function(orderId::Int, status::String, filled::Float64, remaining::Float64, avgFillPrice::Float64, permId::Int, parentId::Int, lastFillPrice::Float64, clientId::Int, whyHeld::String, mktCapPrice::Float64)
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
                   println("orderStatus: $orderId $status")
                 end,

    openOrder= function(orderId::Int, contract::Contract, order::Order, orderstate::OrderState)
                 d[:order_contract] = contract
                 d[:order] = order
                 d[:orderstate] = orderstate
                 println("openOrder: $orderId $(orderstate.status)")
              end,

    openOrderEnd= () -> println("openOrderEnd"),

    updateAccountValue= (key::String, val::String, currency::String, accountName::String) ->
                          println("accountValue: $key $val $currency $accountName"),

    updatePortfolio= (contract::Contract, position::Float64, marketPrice::Float64, marketValue::Float64, averageCost::Float64, unrealizedPNL::Float64, realizedPNL::Float64, accountName::String) ->
                       println("portfolio:  $(contract.symbol) $position $marketPrice $marketValue $averageCost $unrealizedPNL $realizedPNL $accountName"),

    updateAccountTime= (timeStamp::String) -> println("accountTime: $timeStamp"),

    accountDownloadEnd= (accountName::String) -> println("accountDownloadEnd: $accountName"),

    nextValidId= (orderId::Int) -> d[:nextId] = orderId,

    contractDetails = function(reqId::Int, contractDetails::ContractDetails)
                        d[:cd] = contractDetails
                        println("contractDetails: $reqId ", contractDetails.contract.conId)
                      end,

    bondContractDetails = function(reqId::Int, contractDetails::ContractDetails)
                        d[:cdbond] = contractDetails
                        println("bondContractDetails: $reqId ", contractDetails.contract.conId)
                      end,

    contractDetailsEnd= (reqId::Int) -> println("contractDetailsEnd: $reqId"),

    execDetails= function(reqId::Int, contract::Contract, execution::Execution)
                    d[:ex_con] = contract
                    d[:execution] = execution
                    println("execDetails: $reqId")
                 end,

    execDetailsEnd= (reqId::Int) -> println("execDetailsEnd: $reqId"),

    error= (id::Union{Int,Nothing}, errorCode::Union{Int,Nothing}, errorString::String) ->
                     println("error: ",
                             something(id, "NA"), " ",
                             something(errorCode, "NA"), " ",
                             errorString),

    updateMktDepth= (id::Int, position::Int, operation::Int, side::Int, price::Float64, size::Float64) ->
                      println("mktDepth: $id $position $operation $side $price $size"),

    updateMktDepthL2= (id::Int, position::Int, marketMaker::String, operation::Int, side::Int, price::Float64, size::Float64, isSmartDepth::Bool) ->
                        println("mktDepthL2: $id $position $marketMaker $operation $side $price $size $isSmartDepth"),

    updateNewsBulletin= function(msgId::Int, msgType::Int, newsMessage::String, originExch::String)
                          d[:newsbulletin] = newsMessage
                          println("newsBulletin: $msgId $msgType $originExch")
                          println(newsMessage)
                        end,

    managedAccounts= (accountsList::String) -> d[:accounts] = accountsList,

    receiveFA= function(faDataType::FaDataType, xml::String)
                 d[:fa] = xml
                 println("receiveFA: $faDataType")
               end,

    historicalData= function(reqId::Int, bar::DataFrame)
                      d[:history] = bar
                      println("historicalData: $reqId $(size(bar))")
                    end,

    scannerParameters= function(xml::String)
                        d[:scannerparam] = xml
                        println("scannerParameters")
                       end,

    scannerData= function(reqId::Int, rank::Vector{Int}, contractDetails::Vector{ContractDetails}, distance::Vector{String}, benchmark::Vector{String}, projection::Vector{String}, legsStr::Vector{String})
                   d[:scannerdata] = (rank=       rank,
                                      cd=         contractDetails,
                                      distance=   distance,
                                      benchmark=  benchmark,
                                      projection= projection,
                                      legsStr=    legsStr)
                   println("scannerData: $reqId")
                 end,

    realtimeBar= (reqId::Int, time::Int, open::Float64, high::Float64, low::Float64, close::Float64, volume::Float64, wap::Float64, count::Int) ->
                   println("realtimeBar: $reqId $time $open $high, $low $close $volume $wap $count"),

    currentTime= (time::Int) -> println("currentTime: $time"),

    fundamentalData= function(reqId::Int, data::String)
                       d[:fundamental] = data
                       println("fundamentalData: $reqId")
                     end,

    tickSnapshotEnd= (reqId::Int) -> println("tickSnapshotEnd: $reqId"),

    marketDataType= (reqId::Int, marketDataType::MarketDataType) -> println("marketDataType: $reqId $marketDataType"),

    commissionReport= function(commissionReport::CommissionReport)
                        d[:commission] = commissionReport
                        println("commissionReport")
                      end,

    position= (account::String, contract::Contract, position::Float64, avgCost::Float64) ->
                println("position: $account $(contract.symbol) $position $avgCost"),

    positionEnd= () -> println("positionEnd"),

    accountSummary= (reqId::Int, account::String, tag::String, value::String, currency::String) -> println("accountSummary: $reqId $account $tag $value $currency"),

    accountSummaryEnd= (reqId::Int) -> println("accountSummaryEnd: $reqId"),

    displayGroupList= (reqId::Int, groups::String) -> println("displayGroupList: $reqId $groups"),

    displayGroupUpdated= (reqId::Int, contractInfo::String) -> println("displayGroupUpdated: $reqId $contractInfo"),

    positionMulti= (reqId::Int, account::String, modelCode::String, contract::Contract, position::Float64, avgCost::Float64) ->
                     println("positionMulti: $reqId $account $modelCode $(contract.symbol) $position $avgCost"),

    positionMultiEnd= (reqId::Int) -> println("positionMultiEnd $reqId"),

    accountUpdateMulti= (reqId::Int, account::String, modelCode::String, key::String, value::String, currency::String) -> println("accountUpdateMulti: $reqId $account, $modelCode $key=$value $currency"),

    accountUpdateMultiEnd= (reqId::Int) -> println("accountUpdateMultiEnd: $reqId"),

    securityDefinitionOptionalParameter= function(reqId::Int, exchange::String, underlyingConId::Int, tradingClass::String, multiplier::String, expirations::Vector{String}, strikes::Vector{Float64})
                                           d[:sdop] = (e= expirations,
                                                       s= strikes)
                                           println("sdop: $reqId $exchange $underlyingConId $tradingClass $multiplier $(length(expirations)) $(length(strikes))")
                                         end,

    securityDefinitionOptionalParameterEnd= (reqId::Int) -> println("sdopEnd: $reqId"),

    softDollarTiers= function(reqId::Int, tiers::Vector{SoftDollarTier})
                       d[:softdollar] = tiers
                       println("softDollarTiers: $reqId $(length(tiers))")
                     end,

    familyCodes= function(familyCodes::Vector{FamilyCode})
                   d[:familycodes] = familyCodes
                   println("familyCodes: $(length(familyCodes))")
                 end,

    symbolSamples= function(reqId::Int, contractDescriptions::Vector{ContractDescription})
                     d[:symbolsamples] = contractDescriptions
                     println("symbolSamples: $reqId")
                   end,

    mktDepthExchanges= function(depthMktDataDescriptions::DataFrame)
                        d[:mktdepthexchanges] = depthMktDataDescriptions
                        println("mktDepthExchanges")
                      end,

    tickNews= (tickerId::Int, timeStamp::Int, providerCode::String, articleId::String, headline::String, extraData::String) ->
                println("tickNews: $tickerId $timeStamp $providerCode $articleId $headline $extraData"),

    smartComponents= function(reqId::Int, theMap::DataFrame)
                       d[:smartcomponents] = theMap
                       println("smartComponents: $reqId $(size(theMap))")
                     end,

    tickReqParams= (tickerId::Int, minTick::Union{Float64,Nothing}, bboExchange::String, snapshotPermissions::Int) ->
                     println("tickReqParams: $tickerId ",
                             something(minTick, "NA"),
                             " $bboExchange $snapshotPermissions"),

    newsProviders= function(newsProviders::DataFrame)
                     d[:newsproviders] = newsProviders
                     println("newsProviders")
                   end,

    newsArticle= function(requestId::Int, articleType::Int, articleText::String)
                   d[:newsarticle] = articleText
                   println("newsArticle: $requestId $articleType")
                 end,

    historicalNews= function(requestId::Int, time::String, providerCode::String, articleId::String, headline::String)
                      println("historicalNews: $requestId $time $providerCode $articleId $headline")
                    end,

    historicalNewsEnd= (requestId::Int, hasMore::Bool) -> println("historicalNewsEnd: $requestId $hasMore"),

    headTimestamp= (reqId::Int, headTimestamp::String) -> println("headTimestamp: $reqId $headTimestamp"),

    histogramData= function(reqId::Int, data::DataFrame)
                    d[:histogram] = data
                    println("histogramData: $reqId")
                  end,

    historicalDataUpdate= (reqId::Int, bar::NamedTuple) ->
                            println("historicalDataUpdate: $reqId $bar"),

    rerouteMktDataReq= (reqId::Int, conid::Int, exchange::String) ->
                         println("rerouteMktDataReq: $reqId $conid $exchange"),

    rerouteMktDepthReq= (reqId::Int, conid::Int, exchange::String) ->
                          println("rerouteMktDepthReq: $reqId $conid $exchange"),

    marketRule= function(marketRuleId::Int, priceIncrements::DataFrame)
                  d[:marketrule] = priceIncrements
                  println("marketRule: $marketRuleId")
                end,

    pnl= (reqId::Int, dailyPnL::Float64, unrealizedPnL::Float64, realizedPnL::Float64) ->
           println("pnl: $reqId $dailyPnL $unrealizedPnL $realizedPnL"),

    pnlSingle= (reqId::Int, pos::Int, dailyPnL::Float64, unrealizedPnL::Union{Float64,Nothing}, realizedPnL::Union{Float64,Nothing}, value::Float64) ->
                 println("pnlSingle: $reqId $pos $dailyPnL ",
                         something(unrealizedPnL, "NA"), " ",
                         something(realizedPnL, "NA"),   " ",
                         value),

    historicalTicks= function(reqId::Int, ticks::DataFrame, done::Bool)
                       d[:historyticks] = ticks
                       println("historicalTicks: $reqId $done")
                     end,

    historicalTicksBidAsk= function(reqId::Int, ticks::DataFrame, done::Bool)
                             d[:historyticksbidask] = ticks
                             println("historicalTicksBidAsk: $reqId $done")
                           end,

    historicalTicksLast= function(reqId::Int, ticks::DataFrame, done::Bool)
                           d[:historytickslast] = ticks
                           println("historicalTicksLast: $reqId $done")
                         end,

    tickByTickAllLast= (reqId::Int, tickType::Int, time::Int, price::Float64, size::Float64, attribs::TickAttribLast, exchange::String, specialConditions::String) ->
                         println("tickByTickAllLast: $reqId $tickType $time $price $size $attribs $exchange $specialConditions"),

    tickByTickBidAsk= (reqId::Int, time::Int, bidPrice::Float64, askPrice::Float64, bidSize::Float64, askSize::Float64, attribs::TickAttribBidAsk) ->
                        println("tickByTickBidAsk: $reqId $time $bidPrice $askPrice $bidSize $askSize $attribs"),

    tickByTickMidPoint= (reqId::Int, time::Int, midPoint::Float64) ->
                          println("tickByTickMidPoint: $reqId $time $midPoint"),

    orderBound= (orderId::Int, apiClientId::Int, apiOrderId::Int) ->
                  println("orderBound: $orderId $apiClientId $apiOrderId"),

    completedOrder= function(contract::Contract, order::Order, orderState::OrderState)
                      d[:completed_contract] = contract
                      d[:completed] = order
                      d[:completed_state] = orderState
                 println("completedOrder: $(contract.symbol) $(orderState.status)")
              end,

    completedOrdersEnd= () -> println("completedOrdersEnd"),

    replaceFAEnd= (reqId::Int, text::String) -> println("replaceFAEnd: $reqId $text"),

    wshMetaData= (reqId::Int, dataJson::String) -> println("wshMetaData: $reqId $dataJson"),

    wshEventData= (reqId::Int, dataJson::String) -> println("wshEventData: $reqId $dataJson"),
  )

  d, w
end
