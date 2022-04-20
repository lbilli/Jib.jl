@testset "Roundtrip" begin

  i, f, finf, s, b = 10, 12.3, Inf, "a", false

  cl = Jib.ComboLeg(ratio=1, exchange="ex")
  cv = Jib.ConditionVolume("o", true, 1, 2, "ex")


  o = Jib.Requests.Encoder(IOBuffer())

  o(i, f, finf, s, b, Jib.Requests.splat(cl)..., cv)

  msg = take!(o.buf)

  @test pop!(msg) == 0x00

  m = split(String(msg), '\0')

  it = Iterators.Stateful(Jib.Reader.Decoder.Field.(m))

  j::Int,
  g::Float64,
  ginf::Float64,
  z::String,
  l::Bool = it

  cc = Jib.Reader.Decoder.slurp(Jib.ComboLeg, it)

  cw = Jib.Reader.Decoder.slurp(Jib.condition_map[Jib.Reader.Decoder.slurp(Jib.ConditionType, it)], it)

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
