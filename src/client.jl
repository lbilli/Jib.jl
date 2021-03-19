module Client

include("versions.jl")

const API_SIGN = "API\0"
const HEADTYPE = UInt32    # sizeof(HEADTYPE) == 4 bytes
const MAX_LEN =  0xffffff


isascii(m, d) = all(<(0x80), Iterators.drop(m, d))


function write_one(socket, buf)

  s = reset(buf)

  len = bytesavailable(buf) - sizeof(HEADTYPE)

  @assert len ≤ MAX_LEN

  # Write length
  s += write(buf, hton(HEADTYPE(len)))

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

  mark(buf)

  # Leave space for the header
  write(buf, zero(HEADTYPE))

  buf
end

end
