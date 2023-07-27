@testset "Client" begin

  @test sizeof(Jib.Client.HEADTYPE) == 4

  @test Jib.Client.MAX_LEN < typemax(Jib.Client.HEADTYPE)

  # isascii
  @test Jib.Client.isascii([0x80, 0x79, 0x79], 1)

  @test !Jib.Client.isascii([0x80, 0x80, 0x79], 1)

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
  write(buf, "ABC")

  bo = IOBuffer()
  Jib.Client.write_one(bo, buf)

  seekstart(bo) # Rewind
  @test String(Jib.Client.read_one(bo)) == "ABC"
  @test eof(bo)
  @test bo.size == 7

end
