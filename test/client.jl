@testset "Client" begin

  @test sizeof(InteractiveBrokers.Client.HEADTYPE) == 4

  @test InteractiveBrokers.Client.MAX_LEN < typemax(InteractiveBrokers.Client.HEADTYPE)

  # isascii
  @test InteractiveBrokers.Client.isascii([0x80, 0x79, 0x79], 1)

  @test !InteractiveBrokers.Client.isascii([0x80, 0x80, 0x79], 1)

  # buffer
  buf = InteractiveBrokers.Client.buffer(true)
  @test ismarked(buf)
  @test reset(buf) == 8
  @test String(take!(buf)) == InteractiveBrokers.Client.API_SIGN * "\0\0\0\0"

  # write_one
  buf = InteractiveBrokers.Client.buffer(true)
  write(buf, "ABC")
  bo = IOBuffer()
  InteractiveBrokers.Client.write_one(bo, buf)

  @test buf.size == 0
  @test String(take!(bo)) == InteractiveBrokers.Client.API_SIGN * "\0\0\0\x03ABC"

  # Round trip
  buf = InteractiveBrokers.Client.buffer(false)
  write(buf, "ABC")

  bo = IOBuffer()
  InteractiveBrokers.Client.write_one(bo, buf)

  seekstart(bo) # Rewind
  @test String(InteractiveBrokers.Client.read_one(bo)) == "ABC"
  @test eof(bo)
  @test bo.size == 7

end
