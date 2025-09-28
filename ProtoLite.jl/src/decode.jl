function readtag(buf)

  t = readvarint(buf)

  @assert t ≤ typemax(UInt32)

  w = t & 0x07

  id = t >> 3

  UInt32(id), UInt8(w)
end


function readvarint(buf)

  res = zero(UInt64)

  for s ∈ 0x00:0x07:0x3f     # 0:7:63

    b = read(buf, UInt8)

    b < 0x80 && return res | UInt64(b) << s

    res |= UInt64(b & 0x7f) << s
  end

  error("readvarint: never here")
end


function readlen(buf)

  len = readvarint(buf)

  @assert len ≤ typemax(Int32)

  len
end


const decoders = Dict(

  :int32 => function(buf)

              res = readvarint(buf)

              res = reinterpret(Int, res)

              typemin(Int32) ≤ res ≤ typemax(Int32) || @warn "int32 out of bound" V=res

              res
            end,

  :int64 => function(buf)

              res = readvarint(buf)

              reinterpret(Int, res)
            end,

  :bool =>  function(buf)

              res = readvarint(buf)

              @assert res ≤ 0x01

              isone(res)
            end,

  :double => buf -> read(buf, Float64),

  :string => function(buf)

               len = readlen(buf)

               res = String(read(buf, len))

               @assert len == ncodeunits(res)

               res
             end
)


function unpack(buf, decode)

  len = readlen(buf)

  @assert len > 0

  ep = position(buf) + len

  res = [ decode(buf) ]

  while position(buf) < ep

    push!(res, decode(buf))
  end

  @assert position(buf) == ep

  res
end


function decode(desc::Descriptor, buf)

  len = readlen(buf)

  @assert len > 0

  decode(desc, buf, len)
end


function decode(desc::Descriptor, buf, nb)

  ep = position(buf) + nb

  res = Dict{Symbol,Any}()

  while position(buf) < ep

    id, w = readtag(buf)

    fld = desc[id]

    wireassert(w, fld.type)

    if !fld.repeated
      res[fld.name] = fld.decode(buf)

      continue
    end

    val = isprimitive(fld.type) && w === 0x02 ? unpack(buf, fld.decode) : # LEN Unpack
                                                [ fld.decode(buf) ]

    # Update
    x = get(res, fld.name, nothing)

    if isnothing(x)

      res[fld.name] = val
    else

      append!(x, val)
    end

  end

  @assert position(buf) == ep

  Message(desc, res)
end
