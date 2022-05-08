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

  # Symbol
  @test convert(Symbol, v[3]) === :a

  # slurp
  v = ["1", "0", "action", "", "0", "0", "", "-1", ""]
  it = makeit(v)

  @test Jib.Reader.Decoder.slurp((Int, Float64, String), it) === (1, 0., "action")

  @test isnothing(Jib.Reader.Decoder.slurp(Int, it))

  it = makeit(v)
  @test Jib.Reader.Decoder.slurp(Jib.ComboLeg, it) == Jib.ComboLeg(conId=1, action="action")

  it = makeit(v)
  c = Jib.Contract()
  Jib.Reader.Decoder.slurp!(c, (:conId, :secType, :symbol), it)
  @test c.symbol == v[3]

  Jib.Reader.Decoder.slurp!(c, 2:4, it)
  @test c.symbol == v[4]
  @test c.secType == v[5]

  cd = Jib.ContractDetails()
  Jib.Reader.Decoder.slurp!(cd, (:evRule, :evMultiplier), it)
  @test cd.evMultiplier == -1

  # unmask
  @test Jib.Reader.Decoder.unmask(NamedTuple{(:a, :b),NTuple{2,Bool}}, 2) == (a=false, b=true)
  @test_logs (:error, "unmask(): wrong attribs") Jib.Reader.Decoder.unmask(NamedTuple{(:a, :b),NTuple{2,Bool}}, 4)

  # tagvalue2nt()
  v =  ["a", "1", "b", "2"]
  it = makeit(v)
  @test Jib.Reader.Decoder.tagvalue2nt(2, it) == (a="1", b="2")

  # fill_df
  it = makeit(v)
  @test Jib.Reader.Decoder.fill_df((a=String, b=Int), 2, it) == DataFrame(:a => ["a", "b"], :b => [1, 2])

end
