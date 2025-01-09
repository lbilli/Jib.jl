@testset "Utils" begin

  @test InteractiveBrokers.tickname(0) == "BID_SIZE"

  @test InteractiveBrokers.tickname(90) == "DELAYED_HALTED"

  @test InteractiveBrokers.tickname(102) == "FINAL_IPO_LAST"

# InteractiveBrokers does not use that logic. Instead it will throw an error. 
#  @test (@test_logs (:error, "tickname(): unknown ticktype") InteractiveBrokers.tickname(-1)) == "UNKNOWN"

  @test InteractiveBrokers.funddist("Y") == "Income Fund"
  @test InteractiveBrokers.fundtype("003") == "Multi-asset"
  @test InteractiveBrokers.funddist("") == InteractiveBrokers.fundtype("") == "None"

  @test fieldname(InteractiveBrokers.Contract, 15) === :secId
  @test fieldname(InteractiveBrokers.Contract, 17) === :issuerId
  @test fieldname(InteractiveBrokers.Contract, 18) === :lastTradeDate

  @test fieldname(InteractiveBrokers.ContractDetails, 44) === :fundName
  @test fieldname(InteractiveBrokers.ContractDetails, 58) === :fundBlueSkyTerritories

  @test fieldname(InteractiveBrokers.Order, 79) === :account
  @test fieldname(InteractiveBrokers.Order, 125) === :parentPermId

  @test fieldname(InteractiveBrokers.OrderState, 14) === :commissionCurrency
  @test fieldname(InteractiveBrokers.OrderState, 15) === :marginCurrency
  @test fieldname(InteractiveBrokers.OrderState, 27) === :orderAllocations

end
