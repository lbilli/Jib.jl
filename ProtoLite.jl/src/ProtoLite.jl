module ProtoLite

const MAX_ID = typemax(UInt32) >> 3       # 536_870_911
const RESERVED_ID = 0x00004a38:0x00004e1f # 19000:19999

const MAX_LEN = typemax(Int32)     # LEN fields

include("descriptor.jl")
include("pool.jl")
include("decode.jl")
include("encode.jl")
include("utils.jl")


deserialize(desc, data::Vector{UInt8}) = decode(POOL[desc], IOBuffer(data), length(data))

serialize(buf, m::Message) = encode(buf, m)

end # module
