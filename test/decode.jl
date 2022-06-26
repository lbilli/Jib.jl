@testset "Decode" begin

  # Bool
  v = Jib.Reader.Field.(["0", "1", "false", "true", ""])
  @test collect(Bool, v[1:4]) == [false, true, false, true]

  @test_throws ArgumentError convert(Bool, v[5])

  # Int
  v = Jib.Reader.Field.(["", "1", "2147483647", "9223372036854775807", "a"])
  @test collect(Union{Int,Nothing}, v[1:4]) == [nothing, 1, nothing, nothing]

  @test_throws ArgumentError convert(Int, v[5])

  # Float64
  v = Jib.Reader.Field.(["", "1E2", "1.7976931348623157E308", "Infinity", "a"])
  @test collect(Union{Float64,Nothing}, v[1:4]) == [nothing, 100, nothing, Inf]

  @test_throws ArgumentError convert(Float64, v[5])

  # Enum
  v = Jib.Reader.Field.(["1", "2", "a"])
  @test convert(Jib.ConditionType, v[1]) == Jib.PRICE

  @test_throws ArgumentError convert(Jib.ConditionType, v[2])
  @test_throws ArgumentError convert(Jib.ConditionType, v[3])

  # String
  @test collect(String, v) == ["1", "2", "a"]

  # Symbol
  @test convert(Symbol, v[3]) === :a

  v = ["1", "0", "action", "", "0", "0", "", "-1", ""]

  # FieldIterator
  makeit(v) = Jib.Reader.FieldIterator(join([v; ""], '\0'))
  reset!(it) = it.c = 1

  it = makeit(v)
  @test collect(String, it) == v

  @test isempty(it)

  @test_throws EOFError popfirst!(it)

  # slurp
  reset!(it)
  @test Jib.Reader.slurp((Int, Float64, String), it) === (1, 0., "action")

  reset!(it)
  @test Jib.Reader.slurp(Jib.ComboLeg, it) == Jib.ComboLeg(conId=1, action="action")

  reset!(it)
  c = Jib.Contract()
  Jib.Reader.slurp!(c, (:conId, :secType, :symbol), it)
  @test c.symbol == v[3]

  Jib.Reader.slurp!(c, 2:4, it)
  @test c.symbol == v[4]
  @test c.secType == v[5]

  cd = Jib.ContractDetails()
  Jib.Reader.slurp!(cd, (:evRule, :evMultiplier), it)
  @test cd.evMultiplier == -1

  # unmask
  @test Jib.Reader.unmask(NamedTuple{(:a, :b),NTuple{2,Bool}}, 2) == (a=false, b=true)
  @test_logs (:error, "unmask(): wrong attribs") Jib.Reader.unmask(NamedTuple{(:a, :b),NTuple{2,Bool}}, 4)

  # tagvalue2nt()
  v =  ["a", "1", "b", "2"]
  it = makeit(v)
  @test Jib.Reader.tagvalue2nt(2, it) == (a="1", b="2")

  # fill_df
  reset!(it)
  @test Jib.Reader.fill_df((a=String, b=Int), 2, it) == DataFrame(:a => ["a", "b"], :b => [1, 2])

end
