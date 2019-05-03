module Core

const API_SIGN = "API\0"
const HEADTYPE = UInt32    # sizeof(HEADTYPE) == 4 bytes
const MAX_LEN =  0xffffff

using Sockets

isascii(m) = all(x -> x < 0x80, m) # ASCII

function write_one(socket::TCPSocket, buf::IOBuffer, api_sign::Bool=false)

  msg = take!(buf)

  len = length(msg)

  @assert isascii(msg)
  @assert len ≤ MAX_LEN

  api_sign ? write(socket, API_SIGN, hton(HEADTYPE(len)), msg) :
             write(socket,           hton(HEADTYPE(len)), msg)
end


function read_one(socket::TCPSocket)

  len = ntoh(read(socket, HEADTYPE))

  @assert len ≤ MAX_LEN

  read(socket, len)
end

end
