module Client

include("versions.jl")

const API_SIGN = "API\0"
const HEADTYPE = UInt32    # sizeof(HEADTYPE) == 4 bytes
const MAX_LEN =  0xffffff

const RAWIDTYPE = UInt32   # sizeof(RAWIDTYPE) == 4 bytes
const PROTOBUF_MSG_ID = 200


function write_one(socket, buf)

  s = reset(buf)

  len = bytesavailable(buf)

  @assert len ≤ MAX_LEN

  # Rewind and write length
  write(skip(buf, -sizeof(HEADTYPE)), hton(HEADTYPE(len)))

  msg = take!(buf)

  write(socket, msg)
end


function read_init(socket)

  len = ntoh(read(socket, HEADTYPE))

  res = split(String(read(socket, len)), '\0'; keepempty=false)

  @assert length(res) == 2

  parse(Int, res[1]), res[2]
end


function read_one(socket)

  len = ntoh(read(socket, HEADTYPE))

  @assert len ≤ MAX_LEN

  ntoh(read(socket, RAWIDTYPE)), read(socket, len - sizeof(RAWIDTYPE))
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
