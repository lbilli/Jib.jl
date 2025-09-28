data = [([0x00], 0),
        ([0x01], 1),
        ([0xff, 0xff, 0xff, 0xff, 0x0f], typemax(UInt32)),
        ([0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01], typemax(UInt64)),
        ([0x80, 0x01], 128),
        ([0x80, 0x80, 0x01], 1 << 14),
        ([0x80, 0x80, 0x80, 0x01], 1 << 21),
        ([0x80, 0x80, 0x80, 0x80, 0x01], 1 << 28),
        ([0x80, 0x80, 0x80, 0x80, 0x08], 1 << 31),
        ([0xaa, 0xaa, 0xaa, 0x2a], 0x054a952a),
        ([0xaa, 0xaa, 0xaa, 0xaa, 0x2a], 0x2a54a952a),
        ([0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x01], UInt64(1) << 63),
        ([0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0x01], 0xaa54a952a54a952a)]


@testset "Varint" begin

  buf = IOBuffer()

  for (v, r) ∈ data

    write(seekstart(buf), v)

    @test PB.readvarint(seekstart(buf)) == r

    nb = PB.writevarint(seekstart(buf), UInt64(r))

    @test read(seekstart(buf), nb) == v
  end

end

@testset "Codecs" begin

  @test keys(PB.encoders) == keys(PB.decoders)

end


#pbstr = "0885ffffffffffffffff01100c180121d7868a71fe2654bf2a08e28888616263ceb1320a0a036b6579120376616c3a0cf4ffffffffffffffff010c18421000000000000059c000000000000028404a004a01614a08e28888616263ceb152080a026b311202763152080a026b3212027632faffffff0f0104"
pbstr = "100c5208120276310a026b315208120276320a026b322a08e28888616263ceb11801421000000000000059c00000000000002840faffffff0f010421d7868a71fe2654bf3a0cf4ffffffffffffffff010c180885ffffffffffffffff01320a120376616c0a036b65794a004a01614a08e28888616263ceb1"
pb = parse.(UInt8, Iterators.partition(pbstr, 2), base=16)

d = Dict(:a => -123,
         :b => 12,
         :c => true,
         :d => -123e-5,
         :e => "∈abcα",
         :f => Dict(:key => "key", :value => "val"),
         :g => [ -12, 12, 24 ],
         :h => [ -1e2, 12. ],
         :i => [ "", "a", "∈abcα" ],
         :j => [ Dict(:key => "k1", :value => "v1"), Dict(:key => "k2", :value => "v2") ],
         :l => [ 4 ])

mtod(m::PB.Message) = Dict{Symbol,Any}( n => isa(v, PB.Message)         ? mtod(v)  :
                                             isa(v, Vector{PB.Message}) ? mtod.(v) :
                                             v
                                        for (n, v) ∈ m.data )

@testset "Message" begin

  m = PB.deserialize(:Test, pb)

  @test isequal(mtod(m), d)

  buf = IOBuffer()

  PB.serialize(buf, m)

  @test pb == take!(buf)

  m = PB.Message(:Test)

  # only repeated field are stored as vectors
  @test_throws AssertionError m[:a] = [ 1 ]
  @test_throws AssertionError m[:g] = []
  @test_throws AssertionError m[:g] = 1

  # int32 over/underflow
  m[:a] = 2147483648
  @test_throws AssertionError PB.serialize(buf, m)

  m[:a] = -2147483649
  @test_throws AssertionError PB.serialize(buf, m)
end
