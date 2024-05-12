@testset "Utils" begin

    @test InteractiveBrokers.Reader.tickname( 0) == "BID_SIZE"
  
    @test InteractiveBrokers.Reader.tickname(90) == "DELAYED_HALTED"
  
    @test InteractiveBrokers.Reader.tickname(102) == "FINAL_IPO_LAST"
  
    @test (@test_logs (:error, "tickname(): unknown ticktype") InteractiveBrokers.Reader.tickname(-1)) == "UNKNOWN"
  
    @test InteractiveBrokers.funddist("Y") == "Income Fund"
    @test InteractiveBrokers.fundtype("003") == "Multi-asset"
    @test InteractiveBrokers.funddist("") == InteractiveBrokers.fundtype("") == "None"
  
    @test fieldname(InteractiveBrokers.Contract, 15) === :secId
    @test fieldname(InteractiveBrokers.Contract, 17) === :issuerId
  
    @test fieldname(InteractiveBrokers.ContractDetails, 44) === :fundName
    @test fieldname(InteractiveBrokers.ContractDetails, 58) === :fundBlueSkyTerritories
  
    @test fieldname(InteractiveBrokers.Order, 79) === :account
    @test fieldname(InteractiveBrokers.Order, 125) === :parentPermId
  
  end
  