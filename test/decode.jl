@testset "Decode" begin

  makeit(v) = InteractiveBrokers.Reader.FieldIterator(join([v; ""], '\0'))
  reset!(it) = it.c = 1

  take = Iterators.take

  # Bool
  it = makeit(["0", "1", "false", "true", ""])
  @test collect(Bool, take(it, 4)) == [false, true, false, true]

  @test_throws ArgumentError convert(Bool, it)

  # Int
  it = makeit(["", "1", "2147483647", "9223372036854775807", "a"])
  @test collect(Union{Int,Nothing}, take(it, 4)) == [nothing, 1, nothing, nothing]

  @test_throws ArgumentError convert(Int, it)

  # Float64
  it = makeit(["", "1E2", "1.7976931348623157E308", "Infinity", "a"])
  @test collect(Union{Float64,Nothing}, take(it, 4)) == [nothing, 100, nothing, Inf]

  @test_throws ArgumentError convert(Float64, it)

  # Enum
  it = makeit(["1", "2", "a"])
  @test convert(InteractiveBrokers.ConditionType, it) == InteractiveBrokers.PRICE

  @test_throws ArgumentError convert(InteractiveBrokers.ConditionType, it)
  @test_throws ArgumentError convert(InteractiveBrokers.ConditionType, it)

  # Mask
  it = makeit(["4"])
  @test convert(InteractiveBrokers.TickAttrib, it) === InteractiveBrokers.TickAttrib((0, 0, 1))

  # Vector
  it = makeit(["3", "1", "2", "3", "0"])
  @test convert(Vector{Int}, it) == 1:3

  @test typeof(convert(Vector{Int}, it)) === Vector{Int}

  # Vector{<:NamedTuple}
  it = makeit(["1", "2", "3", "0"])
  @test convert(InteractiveBrokers.VHistogramEntry, it) == [(price=2.0, size=3.0)]

  @test typeof(convert(InteractiveBrokers.VHistogramEntry, it)) === InteractiveBrokers.VHistogramEntry

  # NamedTuple
  it = makeit(["2", "a", "1", "b", "2"])
  @test convert(NamedTuple, it) === (a="1", b="2")

  # Condition
  it = makeit(["4", "a", "true", "2"])
  c = InteractiveBrokers.ConditionMargin("a", true, 2)

  @test convert(InteractiveBrokers.AbstractCondition, it) === c

  it = makeit(["1", "4", "a", "true", "2", "0"])
  vc::Vector{InteractiveBrokers.AbstractCondition} = it
  @test vc == [c]
  @test eltype(vc) === InteractiveBrokers.AbstractCondition

  vc = it
  @test typeof(vc) === Vector{InteractiveBrokers.AbstractCondition}

  # String
  v = ["1", "0", "action", "", "0", "0", "", "-1", ""]
  it = makeit(v)

  @test collect(String, take(it, 2)) == v[1:2]

  # Symbol
  @test convert(Symbol, it) === :action

  # rest
  @test collect(String, InteractiveBrokers.Reader.rest(it)) == v[4:end]

  # EOF
  @test isempty(it)
  @test_throws EOFError InteractiveBrokers.Reader.pop(it)

  # Structs
  reset!(it)
  @test convert(InteractiveBrokers.ComboLeg, it) === InteractiveBrokers.ComboLeg(conId=1, action="action")

  # slurp
  reset!(it)
  @test InteractiveBrokers.Reader.slurp((Int, Float64, String), it) === (1, 0.0, "action")

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

  # process
  @test typeof(InteractiveBrokers.Reader.process) == Dict{Int,Function}
end
