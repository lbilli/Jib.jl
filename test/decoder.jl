@testset "Decoder" begin

  # Bool
  v = Jib.Reader.Decoder.Field.(["0", "1", "false", "true", ""])
  @test collect(Bool, v[1:4]) == [false, true, false, true]

  @test_throws ArgumentError convert(Bool, v[5])

  # Int
  v = Jib.Reader.Decoder.Field.(["", "1", "2147483647", "9223372036854775807", "a"])
  @test collect(Union{Int,Nothing}, v[1:4]) == [nothing, 1, nothing, nothing]

  @test_throws ArgumentError convert(Int, v[5])

  # Float64
  v = Jib.Reader.Decoder.Field.(["", "1", "1.7976931348623157E308", "a"])
  @test collect(Union{Float64,Nothing}, v[1:3]) == [nothing, 1, nothing]

  @test_throws ArgumentError convert(Float64, v[4])

  # Enum
  v = Jib.Reader.Decoder.Field.(["1", "2", "a"])
  @test convert(Jib.ConditionType, v[1]) == Jib.PRICE

  @test_throws ArgumentError convert(Jib.ConditionType, v[2])
  @test_throws ArgumentError convert(Jib.ConditionType, v[3])

  # String
  @test collect(String, v) == ["1", "2", "a"]

  # slurp
  v =  Jib.Reader.Decoder.Field.(["1", "0", "action", "", "0", "0", "", "-1", ""])
  it = Iterators.Stateful(v)

  @test Jib.Reader.Decoder.slurp((Int, Float64, String), it) == [1, 0., "action"]

  @test isnothing(Jib.Reader.Decoder.slurp(Int, it))

  it = Iterators.Stateful(v)
  @test Jib.Reader.Decoder.slurp(Jib.ComboLeg, it) == Jib.ComboLeg(conId=1, action="action")

  it = Iterators.Stateful(v)
  c = Jib.Contract()
  Jib.Reader.Decoder.slurp!(c, (:conId, :secType, :symbol), it)
  @test c.symbol == Jib.Contract(symbol="action").symbol == "action"

  # unmask
  @test Jib.Reader.Decoder.unmask(NamedTuple{(:a, :b),NTuple{2,Bool}}, 2) == (a=false, b=true)
  @test_logs (:error, "unmask(): wrong attribs") Jib.Reader.Decoder.unmask(NamedTuple{(:a, :b),NTuple{2,Bool}}, 4)

  # tagvalue2nt()
  v =  Jib.Reader.Decoder.Field.(["a", "1", "b", "2"])
  it = Iterators.Stateful(v)
  @test Jib.Reader.Decoder.tagvalue2nt(Iterators.take(it, 4)) == (a="1", b="2")

  # fill_df
  it = Iterators.Stateful(v)
  @test Jib.Reader.Decoder.fill_df((a=String, b=Int), 2, it) == DataFrame(:a => ["a", "b"], :b => [1, 2])

end
