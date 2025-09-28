@testset "Client" begin

  @test sizeof(Jib.Client.HEADTYPE) == 4
  @test sizeof(Jib.Client.RAWIDTYPE) == 4

  @test Jib.Client.MAX_LEN < typemax(Jib.Client.HEADTYPE)

  # buffer
  buf = Jib.Client.buffer(true)
  @test ismarked(buf)
  @test reset(buf) == 8
  @test String(take!(buf)) == Jib.Client.API_SIGN * "\0\0\0\0"

  # write_one
  buf = Jib.Client.buffer(true)
  write(buf, "ABC")
  bo = IOBuffer()
  Jib.Client.write_one(bo, buf)

  @test buf.size == 0
  @test String(take!(bo)) == Jib.Client.API_SIGN * "\0\0\0\x03ABC"

  # Round trip
  buf = Jib.Client.buffer(false)
  write(buf, hton(Jib.Client.RAWIDTYPE(123)))
  write(buf, "ABC")

  bo = IOBuffer()
  Jib.Client.write_one(bo, buf)

  seekstart(bo) # Rewind
  id, m = Jib.Client.read_one(bo)

  @test id == 123
  @test String(m) == "ABC"
  @test eof(bo)
  @test bo.size == 11

end
