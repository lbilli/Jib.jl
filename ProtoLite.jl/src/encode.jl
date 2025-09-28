function writetag(buf, id::UInt32, w::UInt8)

  writevarint(buf, id << 3 | w)
end


function writelen(buf, len)

  @assert len ≤ typemax(Int32)

  writevarint(buf, UInt32(len))
end


function writevarint(buf, u::Union{UInt32,UInt64})

  count = 0

  while true

    b = u & 0x7f % UInt8

    count += 1

    if u < 0x80

      write(buf, b)

      break
    end

    write(buf, b | 0x80)

    u >>= 7
  end

  count
end


const encoders = Dict(

  :int32 => function(buf, v::Int, id=nothing)

              @assert typemin(Int32) ≤ v ≤ typemax(Int32) "int32 out of bound"

              isnothing(id) || writetag(buf, id, 0x00)  # VARINT

              writevarint(buf, reinterpret(UInt64, v))
            end,

  :int64 => function(buf, v::Int, id=nothing)

              isnothing(id) || writetag(buf, id, 0x00)  # VARINT

              writevarint(buf, reinterpret(UInt64, v))
            end,

  :bool =>  function(buf, v::Bool, id=nothing)

              isnothing(id) || writetag(buf, id, 0x00)  # VARINT

              write(buf, v)
            end,

  :double => function(buf, v::Float64, id=nothing)

               isnothing(id) || writetag(buf, id, 0x01)  # I64

               write(buf, v)
             end,

  :string => function(buf, v::AbstractString, id)

               writetag(buf, id, 0x02)                   # LEN

               len = ncodeunits(v)

               writelen(buf, len)

               @assert write(buf, v) == len
             end
)


function writebuf(bufout, bufin, id)

  seekstart(bufin)

  writetag(bufout, id, 0x02)  # LEN

  len = bytesavailable(bufin)

  writelen(bufout, len)

  write(bufout, bufin)
end


function pack(bufout, v, fld)

  buf = IOBuffer()

  for e ∈ v
    fld.encode(buf, e)
  end

  writebuf(bufout, buf, fld.id)
end


function encode(bufout, m::Message, id=nothing)

  buf = isnothing(id) ? bufout : IOBuffer()

  for (name, v) ∈ m.data

    fld = m.desc[name]

    !fld.repeated         ? fld.encode(buf, v, fld.id) :
    isprimitive(fld.type) ? pack(buf, v, fld)     :
                            foreach(e -> fld.encode(buf, e, fld.id), v)
  end

  isnothing(id) || writebuf(bufout, buf, id)
end
