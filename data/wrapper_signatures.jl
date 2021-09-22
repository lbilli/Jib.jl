tickPrice= function(tickerId::Int, field::String, price::Float64, size::Float64, attrib::TickAttrib)

tickSize= function(tickerId::Int, field::String, size::Float64)

tickOptionComputation= function(tickerId::Int, tickType::String, tickAttrib::Union{Int,Nothing}, impliedVol::Union{Float64,Nothing}, delta::Union{Float64,Nothing}, optPrice::Union{Float64,Nothing}, pvDividend::Union{Float64,Nothing}, gamma::Union{Float64,Nothing}, vega::Union{Float64,Nothing}, theta::Union{Float64,Nothing}, undPrice::Union{Float64,Nothing})

tickGeneric= function(tickerId::Int, tickType::String, value::Float64)

tickString= function(tickerId::Int, tickType::String, value::String)

tickEFP= function(tickerId::Int, tickType::String, basisPoints::Float64, formattedBasisPoints::String, totalDividends::Float64, holdDays::Int, futureLastTradeDate::String, dividendImpact::Float64, dividendsToLastTradeDate::Float64)

orderStatus= function(orderId::Int, status::String, filled::Float64, remaining::Float64, avgFillPrice::Float64, permId::Int, parentId::Int, lastFillPrice::Float64, clientId::Int, whyHeld::String, mktCapPrice::Float64)

openOrder= function(orderId::Int, contract::Contract, order::Order, orderstate::OrderState)

openOrderEnd= function()

updateAccountValue= function(key::String, val::String, currency::String, accountName::String)

updatePortfolio= function(contract::Contract, position::Float64, marketPrice::Float64, marketValue::Float64, averageCost::Float64, unrealizedPNL::Float64, realizedPNL::Float64, accountName::String)

updateAccountTime= function(timeStamp::String)

accountDownloadEnd= function(accountName::String)

nextValidId= function(orderId::Int)

contractDetails= function(reqId::Int, contractDetails::ContractDetails)

bondContractDetails= function(reqId::Int, contractDetails::ContractDetails)

contractDetailsEnd= function(reqId::Int)

execDetails= function(reqId::Int, contract::Contract, execution::Execution)

execDetailsEnd= function(reqId::Int)

error= function(id::Union{Int,Nothing}, errorCode::Union{Int,Nothing}, errorString::String)

updateMktDepth= function(id::Int, position::Int, operation::Int, side::Int, price::Float64, size::Float64)

updateMktDepthL2= function(id::Int, position::Int, marketMaker::String, operation::Int, side::Int, price::Float64, size::Float64, isSmartDepth::Bool)

updateNewsBulletin= function(msgId::Int, msgType::Int, newsMessage::String, originExch::String)

managedAccounts= function(accountsList::String)

receiveFA= function(faDataType::FaDataType, xml::String)

historicalData= function(reqId::Int, bar::DataFrame)

scannerParameters= function(xml::String)

scannerData= function(reqId::Int, rank::Vector{Int}, contractDetails::Vector{ContractDetails}, distance::Vector{String}, benchmark::Vector{String}, projection::Vector{String}, legsStr::Vector{String})

realtimeBar= function(reqId::Int, time::Int, open::Float64, high::Float64, low::Float64, close::Float64, volume::Float64, wap::Float64, count::Int)

currentTime= function(time::Int)

fundamentalData= function(reqId::Int, data::String)

deltaNeutralValidation= function(reqId::Int, deltaNeutralContract::DeltaNeutralContract)

tickSnapshotEnd= function(reqId::Int)

marketDataType= function(reqId::Int, marketDataType::MarketDataType)

commissionReport= function(commissionReport::CommissionReport)

position= function(account::String, contract::Contract, position::Float64, avgCost::Float64)

positionEnd= function()

accountSummary= function(reqId::Int, account::String, tag::String, value::String, currency::String)

accountSummaryEnd= function(reqId::Int)

verifyMessageAPI= function(apiData::String)

verifyCompleted= function(isSuccessful::Bool, errorText::String)

displayGroupList= function(reqId::Int, groups::String)

displayGroupUpdated= function(reqId::Int, contractInfo::String)

verifyAndAuthMessageAPI= function(apiData::String, xyzChallange::String)

verifyAndAuthCompleted= function(isSuccessful::Bool, errorText::String)

positionMulti= function(reqId::Int, account::String, modelCode::String, contract::Contract, position::Float64, avgCost::Float64)

positionMultiEnd= function(reqId::Int)

accountUpdateMulti= function(reqId::Int, account::String, modelCode::String, key::String, value::String, currency::String)

accountUpdateMultiEnd= function(reqId::Int)

securityDefinitionOptionalParameter= function(reqId::Int, exchange::String, underlyingConId::Int, tradingClass::String, multiplier::String, expirations::Vector{String}, strikes::Vector{Float64})

securityDefinitionOptionalParameterEnd= function(reqId::Int)

softDollarTiers= function(reqId::Int, tiers::Vector{SoftDollarTier})

familyCodes= function(familyCodes::Vector{FamilyCode})

symbolSamples= function(reqId::Int, contractDescriptions::Vector{ContractDescription})

mktDepthExchanges= function(depthMktDataDescriptions::DataFrame)

tickNews= function(tickerId::Int, timeStamp::Int, providerCode::String, articleId::String, headline::String, extraData::String)

smartComponents= function(reqId::Int, theMap::DataFrame)

tickReqParams= function(tickerId::Int, minTick::Union{Float64,Nothing}, bboExchange::String, snapshotPermissions::Int)

newsProviders= function(newsProviders::DataFrame)

newsArticle= function(requestId::Int, articleType::Int, articleText::String)

historicalNews= function(requestId::Int, time::String, providerCode::String, articleId::String, headline::String)

historicalNewsEnd= function(requestId::Int, hasMore::Bool)

headTimestamp= function(reqId::Int, headTimestamp::String)

histogramData= function(reqId::Int, data::DataFrame)

historicalDataUpdate= function(reqId::Int, bar::NamedTuple)

rerouteMktDataReq= function(reqId::Int, conid::Int, exchange::String)

rerouteMktDepthReq= function(reqId::Int, conid::Int, exchange::String)

marketRule= function(marketRuleId::Int, priceIncrements::DataFrame)

pnl= function(reqId::Int, dailyPnL::Float64, unrealizedPnL::Float64, realizedPnL::Float64)

pnlSingle= function(reqId::Int, pos::Int, dailyPnL::Float64, unrealizedPnL::Union{Float64,Nothing}, realizedPnL::Union{Float64,Nothing}, value::Float64)

historicalTicks= function(reqId::Int, ticks::DataFrame, done::Bool)

historicalTicksBidAsk= function(reqId::Int, ticks::DataFrame, done::Bool)

historicalTicksLast= function(reqId::Int, ticks::DataFrame, done::Bool)

tickByTickAllLast= function(reqId::Int, tickType::Int, time::Int, price::Float64, size::Float64, attribs::TickAttribLast, exchange::String, specialConditions::String)

tickByTickBidAsk= function(reqId::Int, time::Int, bidPrice::Float64, askPrice::Float64, bidSize::Float64, askSize::Float64, attribs::TickAttribBidAsk)

tickByTickMidPoint= function(reqId::Int, time::Int, midPoint::Float64)

orderBound= function(orderId::Int, apiClientId::Int, apiOrderId::Int)

completedOrder= function(contract::Contract, order::Order, orderState::OrderState)

completedOrdersEnd= function()

replaceFAEnd= function(reqId::Int, text::String)
