module Connect

using Sockets

using ..Client: Core, Connection, Version
using ..Reader: read_msg
using ..Requests: Encoder.Enc, startApi

import ..from_ibtime

function connect(port::Int, clientId::Int, connectOptions::String="", optionalCapabilities::String="")

  s = Sockets.connect(port)

  @assert isopen(s)

  o = Enc()

  o(init_string(connectOptions))

  Core.write_one(s, o.buf, true)

  res = read_msg(s)

  @assert length(res) == 2

  @info "Connected" ver=res[1] t=res[2]

  ib = Connection(s, clientId, connectOptions, Version(parse(Int, res[1])), from_ibtime(res[2]))

  startApi(ib, clientId, optionalCapabilities)

  ib
end

disconnect(ib::Connection) = close(ib.socket)


function init_string(options::String)

  m, M = Int(typemin(Version)), Int(typemax(Version))

  res = m == M ? "v$m" : "v$m..$M"

  isempty(options) ? res : "$res $options"
end

end
