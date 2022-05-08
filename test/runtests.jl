using Test,
      DataFrames,
      Jib

makeit(v) = Iterators.Stateful(Iterators.map(Jib.Reader.Decoder.Field, v))

include("client.jl")
include("decoder.jl")
include("requests.jl")
include("roundtrip.jl")


@testset "TickType" begin

  @test Jib.Reader.Decoder.tickname( 0) == "BID_SIZE"

  @test Jib.Reader.Decoder.tickname(90) == "DELAYED_HALTED"

  @test Jib.Reader.Decoder.tickname(102) == "FINAL_IPO_LAST"

end
