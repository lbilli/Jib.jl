@testset "Decode" begin

  makeit(v) = Jib.Reader.FieldIterator(join([v; ""], '\0'))
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
  @test convert(Jib.ConditionType, it) == Jib.PRICE

  @test_throws ArgumentError convert(Jib.ConditionType, it)
  @test_throws ArgumentError convert(Jib.ConditionType, it)

  # Mask
  it = makeit(["4"])
  @test convert(Jib.TickAttrib, it) === Jib.TickAttrib((0, 0, 1))

  # Vector
  it = makeit(["3", "1", "2", "3", "0"])
  @test convert(Vector{Int}, it) == 1:3

  @test typeof(convert(Vector{Int}, it)) === Vector{Int}

  # Vector{<:NamedTuple}
  it = makeit(["1", "2", "3", "0"])
  @test convert(Jib.VHistogramEntry, it) == [(price = 2.0, size = 3.0)]

  @test typeof(convert(Jib.VHistogramEntry, it)) === Jib.VHistogramEntry

  # NamedTuple
  it = makeit(["2", "a", "1", "b", "2"])
  @test convert(NamedTuple, it) === (a="1", b="2")

  # Condition
  it = makeit(["4", "a", "true", "2"])
  c = Jib.ConditionMargin("a", true, 2)

  @test convert(Jib.AbstractCondition, it) === c

  it = makeit(["1", "4", "a", "true", "2", "0"])
  vc::Vector{Jib.AbstractCondition} = it
  @test vc == [c]
  @test eltype(vc) === Jib.AbstractCondition

  vc = it
  @test typeof(vc) === Vector{Jib.AbstractCondition}

  # String
  v = ["1", "0", "action", "", "0", "0", "", "-1", ""]
  it = makeit(v)

  @test collect(String, take(it, 2)) == v[1:2]

  # Symbol
  @test convert(Symbol, it) === :action

  # rest
  @test collect(String, Jib.Reader.rest(it)) == v[4:end]

  # EOF
  @test isempty(it)
  @test_throws EOFError Jib.Reader.pop(it)

  # Structs
  reset!(it)
  @test convert(Jib.ComboLeg, it) === Jib.ComboLeg(conId=1, action="action")

  # slurp
  reset!(it)
  @test Jib.Reader.slurp((Int, Float64, String), it) === (1, 0., "action")

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

  # process
  @test typeof(Jib.Reader.process) == Dict{Int,Function}
end
