function parsemsg(m)

  buf = IOBuffer(m)

  res = Tuple{UInt32,UInt8,Union{UInt64,Vector{UInt8}}}[]

  while !eof(buf)

    id, w = readtag(buf)

    payload = w === 0x00 ? readvarint(buf)            : # VARINT
              w === 0x01 ? read(buf, UInt64)          : # I64
              w === 0x02 ? read(buf, readvarint(buf)) : # LEN
                           error("unknown wire type $w")

    push!(res, (id, w, payload))
  end

  res
end
