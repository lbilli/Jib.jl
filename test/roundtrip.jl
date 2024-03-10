@testset "Roundtrip" begin

  i, f, finf, s, b = 10, 12.3, Inf, "a", false

  cl = InteractiveBrokers.ComboLeg(ratio=1, exchange="ex")
  cv = InteractiveBrokers.ConditionVolume("o", true, 1, 2, "ex")


  o = InteractiveBrokers.Requests.Encoder(IOBuffer())

  o(i, f, finf, s, b, InteractiveBrokers.Requests.splat(cl)..., cv)

  msg = take!(o.buf)

  it = InteractiveBrokers.Reader.FieldIterator(String(msg))

  j::Int,
  g::Float64,
  ginf::Float64,
  z::String,
  l::Bool = it

  cc = InteractiveBrokers.Reader.slurp(InteractiveBrokers.ComboLeg, it)

  cw = InteractiveBrokers.Reader.slurp(InteractiveBrokers.condition_map[InteractiveBrokers.Reader.slurp(InteractiveBrokers.ConditionType, it)], it)

  @test i == j
  @test f == g
  @test finf == ginf
  @test s == z
  @test b == l
  @test cl == cc
  @test cv == cw

  @test isempty(it)

  @test_throws EOFError popfirst!(it)

end
