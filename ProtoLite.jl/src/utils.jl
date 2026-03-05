payload(buf, w) = w === 0x00 ? readvarint(buf)            : # VARINT
                  w === 0x01 ? read(buf, UInt64)          : # I64
                  w === 0x02 ? read(buf, readvarint(buf)) : # LEN
                               error("unknown wire type $w")


function parsemsg(m)

  buf = IOBuffer(m)

  res = Tuple{UInt32,UInt8,Union{UInt64,Vector{UInt8}}}[]

  while !eof(buf)

    id, w = readtag(buf)

    push!(res, (id, w, payload(buf, w)))
  end

  res
end


unwrap(x) = x
unwrap(v::Vector{Message}) = unwrap.(v)
unwrap(m::Message) = Dict{Symbol,Any}( n => unwrap(v) for (n, v) ∈ m.data )


wrap(x, t) = (@assert isscalar(t); x)
wrap(x::Vector, t) = wrap.(x, Ref(t))

function wrap(d::Union{Dict,NamedTuple}, desc::Symbol)

  pb = Message(desc)

  for (n, v) ∈ pairs(d)
    pb[n] = wrap(v, pb.desc[n].type)
  end

  pb
end
