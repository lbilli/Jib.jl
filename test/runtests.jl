using Test,
      DataFrames,
      Jib

include("client.jl")
include("decode.jl")
include("requests.jl")
include("roundtrip.jl")


@testset "Utils" begin

  @test Jib.Reader.tickname( 0) == "BID_SIZE"

  @test Jib.Reader.tickname(90) == "DELAYED_HALTED"

  @test Jib.Reader.tickname(102) == "FINAL_IPO_LAST"

  @test (@test_logs (:error, "tickname(): unknown ticktype") Jib.Reader.tickname(-1)) == "UNKNOWN"

  @test Jib.funddist("Y") == "Income Fund"
  @test Jib.fundtype("003") == "Multi-asset"
  @test Jib.funddist("") == Jib.fundtype("") == "None"

  @test fieldname(Jib.Contract, 15) === :secId
  @test fieldname(Jib.Contract, 17) === :issuerId

  @test fieldname(Jib.ContractDetails, 44) === :fundName
  @test fieldname(Jib.ContractDetails, 58) === :fundBlueSkyTerritories

  @test fieldname(Jib.Order, 79) === :account
  @test fieldname(Jib.Order, 125) === :parentPermId

end
