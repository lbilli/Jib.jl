@testset "Requests" begin

  o = Jib.Requests.Encoder(IOBuffer())

  o(nothing, true, 1, 1.1, Inf, Jib.PRICE, :a, "test", (a=1, b="2", c=3.2))

  m = split(String(take!(o.buf)), '\0')

  @test m == ["",               # nothing
              "1",              # Bool
              "1",              # Int
              "1.1",            # Float64
              "Infinity",       # Inf
              "1",              # Enum{Int32}
              "a",              # Symbol
              "test",           # String
              "a=1;b=2;c=3.2;", # NamedTuple
              ""]

  # Condition
  o(Jib.ConditionTime("o", true, "yyyymmdd"))
  @test String(take!(o.buf)) == "3\0o\x001\0yyyymmdd\0"

  # splat
  c = Jib.ComboLeg(conId=1, action="action")
  o(Jib.Requests.splat(c, [1,3]),
    Jib.Requests.splat(c))

  m = split(String(take!(o.buf)), '\0')
  @test m == ["1", "action", "1", "0", "action", "", "0", "0", "", "-1", ""]

  # Unsuported types
  @test_throws ErrorException o(Int32(2))
  @test_throws ErrorException o(Float32(1))

end
