@testset "Core" begin

  @test sizeof(Jib.Client.Core.HEADTYPE) == 4

  @test Jib.Client.Core.MAX_LEN < typemax(Jib.Client.Core.HEADTYPE)

  @test Jib.Client.Core.isascii([0x45, 0x79])

  @test !Jib.Client.Core.isascii([0x45, 0x80])

end
