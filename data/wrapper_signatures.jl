tickPrice(reqId::Int, field::String, price::Union{Float64,Nothing}, size::Union{Float64,Nothing}, attrib::TickAttrib)

tickSize(reqId::Int, field::String, size::Float64)

tickOptionComputation(reqId::Int, tickType::String, tickAttrib::Int, impliedVol::Union{Float64,Nothing}, delta::Union{Float64,Nothing}, optPrice::Union{Float64,Nothing}, pvDividend::Union{Float64,Nothing}, gamma::Union{Float64,Nothing}, vega::Union{Float64,Nothing}, theta::Union{Float64,Nothing}, undPrice::Union{Float64,Nothing})

tickGeneric(reqId::Int, tickType::String, value::Float64)

tickString(reqId::Int, tickType::String, value::String)

tickEFP(reqId::Int, tickType::String, basisPoints::Float64, formattedBasisPoints::String, totalDividends::Float64, holdDays::Int, futureLastTradeDate::String, dividendImpact::Float64, dividendsToLastTradeDate::Float64)

orderStatus(orderId::Int, status::String, filled::Float64, remaining::Float64, avgFillPrice::Float64, permId::Int, parentId::Int, lastFillPrice::Float64, clientId::Int, whyHeld::String, mktCapPrice::Float64)

openOrder(orderId::Int, contract::Contract, order::Order, orderState::OrderState)

openOrderEnd()

updateAccountValue(key::String, val::String, currency::String, accountName::String)

updatePortfolio(contract::Contract, position::Float64, marketPrice::Float64, marketValue::Float64, averageCost::Float64, unrealizedPNL::Float64, realizedPNL::Float64, accountName::String)

updateAccountTime(timestamp::String)

accountDownloadEnd(accountName::String)

nextValidId(orderId::Int)

contractDetails(reqId::Int, contractDetails::ContractDetails)

bondContractDetails(reqId::Int, contractDetails::ContractDetails)

contractDetailsEnd(reqId::Int)

execDetails(reqId::Int, contract::Contract, execution::Execution)

execDetailsEnd(reqId::Int)

error(id::Union{Int,Nothing}, errorTime::Int, errorCode::Union{Int,Nothing}, errorString::String, advancedOrderRejectJson::String)

updateMktDepth(id::Int, position::Int, operation::Int, side::Int, price::Float64, size::Float64)

updateMktDepthL2(id::Int, position::Int, marketMaker::String, operation::Int, side::Int, price::Float64, size::Float64, isSmartDepth::Bool)

updateNewsBulletin(msgId::Int, msgType::Int, newsMessage::String, originExch::String)

managedAccounts(accountsList::String)

receiveFA(faDataType::FaDataType, xml::String)

historicalData(reqId::Int, bars::VBar)

scannerParameters(xml::String)

scannerData(reqId::Int, data::VScannerDataElement)

realtimeBar(reqId::Int, time::Int, open::Float64, high::Float64, low::Float64, close::Float64, volume::Float64, wap::Float64, count::Int)

currentTime(time::Int)

fundamentalData(reqId::Int, data::String)

deltaNeutralValidation(reqId::Int, deltaNeutralContract::DeltaNeutralContract)

tickSnapshotEnd(reqId::Int)

marketDataType(reqId::Int, marketDataType::MarketDataType)

commissionReport(commissionReport::CommissionReport)

position(account::String, contract::Contract, position::Float64, avgCost::Float64)

positionEnd()

accountSummary(reqId::Int, account::String, tag::String, value::String, currency::String)

accountSummaryEnd(reqId::Int)

verifyMessageAPI(apiData::String)

verifyCompleted(isSuccessful::Bool, errorText::String)

displayGroupList(reqId::Int, groups::String)

displayGroupUpdated(reqId::Int, contractInfo::String)

verifyAndAuthMessageAPI(apiData::String, xyzChallange::String)

verifyAndAuthCompleted(isSuccessful::Bool, errorText::String)

positionMulti(reqId::Int, account::String, modelCode::String, contract::Contract, position::Float64, avgCost::Float64)

positionMultiEnd(reqId::Int)

accountUpdateMulti(reqId::Int, account::String, modelCode::String, key::String, value::String, currency::String)

accountUpdateMultiEnd(reqId::Int)

securityDefinitionOptionalParameter(reqId::Int, exchange::String, underlyingConId::Int, tradingClass::String, multiplier::String, expirations::Vector{String}, strikes::Vector{Float64})

securityDefinitionOptionalParameterEnd(reqId::Int)

softDollarTiers(reqId::Int, tiers::Vector{SoftDollarTier})

familyCodes(familyCodes::VFamilyCode)

symbolSamples(reqId::Int, contractDescriptions::Vector{ContractDescription})

mktDepthExchanges(depthMktDataDescriptions::VDepthMktDataDescription)

tickNews(reqId::Int, timestamp::Int, providerCode::String, articleId::String, headline::String, extraData::String)

smartComponents(reqId::Int, theMap::VSmartComponent)

tickReqParams(reqId::Int, minTick::Union{Float64,Nothing}, bboExchange::String, snapshotPermissions::Int)

newsProviders(newsProviders::VNewsProvider)

newsArticle(reqId::Int, articleType::Int, articleText::String)

historicalNews(reqId::Int, time::String, providerCode::String, articleId::String, headline::String)

historicalNewsEnd(reqId::Int, hasMore::Bool)

headTimestamp(reqId::Int, headTimestamp::String)

histogramData(reqId::Int, data::VHistogramEntry)

historicalDataUpdate(reqId::Int, bar::Bar)

rerouteMktDataReq(reqId::Int, conId::Int, exchange::String)

rerouteMktDepthReq(reqId::Int, conId::Int, exchange::String)

marketRule(marketRuleId::Int, priceIncrements::VPriceIncrement)

pnl(reqId::Int, dailyPnL::Float64, unrealizedPnL::Float64, realizedPnL::Float64)

pnlSingle(reqId::Int, pos::Float64, dailyPnL::Union{Float64,Nothing}, unrealizedPnL::Union{Float64,Nothing}, realizedPnL::Union{Float64,Nothing}, value::Float64)

historicalTicks(reqId::Int, ticks::VTick, done::Bool)

historicalTicksBidAsk(reqId::Int, ticks::VTickBidAsk, done::Bool)

historicalTicksLast(reqId::Int, ticks::VTickLast, done::Bool)

tickByTickAllLast(reqId::Int, tickType::Int, time::Int, price::Float64, size::Float64, attribs::TickAttribLast, exchange::String, specialConditions::String)

tickByTickBidAsk(reqId::Int, time::Int, bidPrice::Float64, askPrice::Float64, bidSize::Float64, askSize::Float64, attribs::TickAttribBidAsk)

tickByTickMidPoint(reqId::Int, time::Int, price::Float64)

orderBound(permId::Int, clientId::Int, orderId::Int)

completedOrder(contract::Contract, order::Order, orderState::OrderState)

completedOrdersEnd()

replaceFAEnd(reqId::Int, text::String)

wshMetaData(reqId::Int, dataJson::String)

wshEventData(reqId::Int, dataJson::String)

historicalSchedule(reqId::Int, startDateTime::String, endDateTime::String, timeZone::String, sessions::VHistoricalSession)

userInfo(reqId::Int, whiteBrandingId::String)

historicalDataEnd(reqId::Int, startDateStr::String, endDateStr::String)

currentTimeInMillis(timeInMillis::Int)
