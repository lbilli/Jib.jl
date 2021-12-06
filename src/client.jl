module Client

include("versions.jl")

const API_SIGN = "API\0"
const HEADTYPE = UInt32    # sizeof(HEADTYPE) == 4 bytes
const MAX_LEN =  0xffffff


isascii(m, d) = all(<(0x80), Iterators.drop(m, d))


function write_one(socket, buf)

  s = reset(buf)

  len = bytesavailable(buf)

  @assert len ≤ MAX_LEN

  # Rewind and write length
  write(skip(buf, -sizeof(HEADTYPE)), hton(HEADTYPE(len)))

  msg = take!(buf)

  @assert isascii(msg, s)

  write(socket, msg)
end


function read_one(socket)

  len = ntoh(read(socket, HEADTYPE))

  @assert len ≤ MAX_LEN

  read(socket, len)
end


function buffer(sign)

  buf = IOBuffer(sizehint=64)

  sign && write(buf, API_SIGN)

  # Leave space for the header
  write(buf, zero(HEADTYPE))

  mark(buf)

  buf
end

end
