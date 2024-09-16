@testset "Roundtrip" begin

  i, f, finf, s, b, e, nt, v = 10, 12.3, Inf, "a", false, Jib.FIRM, (a=1, b="c"), [1, 2]

  cl = Jib.ComboLeg(ratio=1, exchange="ex")
  cv = [ Jib.ConditionPrice("a", false, 1.5, 5, "A", 2),
         Jib.ConditionVolume("o", true, 1, 2, "ex") ]


  o = Jib.Requests.Encoder(IOBuffer())

  o(i, f, finf, s, b, e)
  Jib.Requests.splatnt(o, nt)
  o(length(v), v..., Jib.Requests.splat(cl)..., length(cv), cv...)

  msg = String(take!(o.buf))

  it = Jib.Reader.FieldIterator(msg)

  j::Int,
  g::Float64,
  ginf::Float64,
  z::String,
  l::Bool,
  en::Jib.Origin,
  mt::NamedTuple,
  w::Vector{Int},
  cc::Jib.ComboLeg,
  cw::Vector{Jib.AbstractCondition} = it

  @test i == j
  @test f == g
  @test finf == ginf
  @test s == z
  @test b == l
  @test e == en
  @test (a="1", b="c") == mt
  @test v == w
  @test cl == cc
  @test cv == cw

  @test isempty(it)
end
