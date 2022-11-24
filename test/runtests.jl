using Test,
      DataFrames,
      Jib

include("client.jl")
include("decode.jl")
include("requests.jl")
include("roundtrip.jl")


@testset "TickType" begin

  @test Jib.Reader.tickname( 0) == "BID_SIZE"

  @test Jib.Reader.tickname(90) == "DELAYED_HALTED"

  @test Jib.Reader.tickname(102) == "FINAL_IPO_LAST"

  @test (@test_logs (:error, "tickname(): unknown ticktype") Jib.Reader.tickname(-1)) == "UNKNOWN"

end
