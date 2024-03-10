@testset "Decode" begin

  # Bool
  v = InteractiveBrokers.Reader.Field.(["0", "1", "false", "true", ""])
  @test collect(Bool, v[1:4]) == [false, true, false, true]

  @test_throws ArgumentError convert(Bool, v[5])

  # Int
  v = InteractiveBrokers.Reader.Field.(["", "1", "2147483647", "9223372036854775807", "a"])
  @test collect(Union{Int,Nothing}, v[1:4]) == [nothing, 1, nothing, nothing]

  @test_throws ArgumentError convert(Int, v[5])

  # Float64
  v = InteractiveBrokers.Reader.Field.(["", "1E2", "1.7976931348623157E308", "Infinity", "a"])
  @test collect(Union{Float64,Nothing}, v[1:4]) == [nothing, 100, nothing, Inf]

  @test_throws ArgumentError convert(Float64, v[5])

  # Enum
  v = InteractiveBrokers.Reader.Field.(["1", "2", "a"])
  @test convert(InteractiveBrokers.ConditionType, v[1]) == InteractiveBrokers.PRICE

  @test_throws ArgumentError convert(InteractiveBrokers.ConditionType, v[2])
  @test_throws ArgumentError convert(InteractiveBrokers.ConditionType, v[3])

  # String
  @test collect(String, v) == ["1", "2", "a"]

  # Symbol
  @test convert(Symbol, v[3]) === :a

  v = ["1", "0", "action", "", "0", "0", "", "-1", ""]

  # FieldIterator
  makeit(v) = InteractiveBrokers.Reader.FieldIterator(join([v; ""], '\0'))
  reset!(it) = it.c = 1

  it = makeit(v)
  @test collect(String, it) == v

  @test isempty(it)

  @test_throws EOFError popfirst!(it)

  # slurp
  reset!(it)
  @test InteractiveBrokers.Reader.slurp((Int, Float64, String), it) === (1, 0.0, "action")

  reset!(it)
  @test InteractiveBrokers.Reader.slurp(InteractiveBrokers.ComboLeg, it) == InteractiveBrokers.ComboLeg(conId=1, action="action")

  reset!(it)
  c = InteractiveBrokers.Contract()
  InteractiveBrokers.Reader.slurp!(c, (:conId, :secType, :symbol), it)
  @test c.symbol == v[3]

  InteractiveBrokers.Reader.slurp!(c, 2:4, it)
  @test c.symbol == v[4]
  @test c.secType == v[5]

  cd = InteractiveBrokers.ContractDetails()
  InteractiveBrokers.Reader.slurp!(cd, (:evRule, :evMultiplier), it)
  @test cd.evMultiplier == -1

  # unmask
  @test InteractiveBrokers.Reader.unmask(NamedTuple{(:a, :b),NTuple{2,Bool}}, 2) == (a=false, b=true)
  @test_logs (:error, "unmask(): wrong attribs") InteractiveBrokers.Reader.unmask(NamedTuple{(:a, :b),NTuple{2,Bool}}, 4)

  # tagvalue2nt()
  v = ["a", "1", "b", "2"]
  it = makeit(v)
  @test InteractiveBrokers.Reader.tagvalue2nt(2, it) == (a="1", b="2")

  # fill_table
  reset!(it)
  # Test default implementation
  dict = Dict{Symbol,Vector}()
  dict[:a] = ["a", "b"]
  dict[:b] = [1, 2]
  @test InteractiveBrokers.Reader.fill_table((a=String, b=Int), 2, it) == dict

  # Test for DataFrames
  reset!(it)
  @test InteractiveBrokers.Reader.fill_table((a=String, b=Int), 2, it, DataFrame) == DataFrame(:a => ["a", "b"], :b => [1, 2])


  # process
  @test typeof(InteractiveBrokers.Reader.process) == Dict{Int,Function}
end
