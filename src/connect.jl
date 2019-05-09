module Connect

using Sockets

using ..Client: Core, Connection, Version
using ..Reader: read_msg
using ..Requests: startApi

import ..from_ibtime

"""
    connect([host, ]port, clientId, connectOptions="", optionalCapabilities="")

Connect to host `host` on port `port` and set client ID `clientId`.

Return a [`Connection`](@ref) instance.
"""
function connect(host, port::Int, clientId::Int, connectOptions::String="", optionalCapabilities::String="")

  s = Sockets.connect(host, port)

  @assert isopen(s)

  # Init string
  m, M = Int(typemin(Version)), Int(typemax(Version))

  buf = IOBuffer()
  print(buf, m==M ? "v$m" : "v$m..$M")
  isempty(connectOptions) || print(buf, " ", connectOptions)

  # Handshake
  Core.write_one(s, buf, true)

  res = read_msg(s)

  @assert length(res) == 2

  @info "Connected" V=res[1] T=res[2]

  v = parse(Int, res[1])
  m ≤ v ≤ M || error("Unsupported version.")

  ib = Connection(s, clientId, connectOptions, Version(v), from_ibtime(res[2]))

  startApi(ib, clientId, optionalCapabilities)

  ib
end

function connect(port::Int, clientId::Int, connectOptions::String="", optionalCapabilities::String="")

  localip = getalladdrinfo("localhost")

  @assert !isempty(localip)

  connect(localip[1], port, clientId, connectOptions, optionalCapabilities)
end


"""
    disconnect(ib)

Close the socket connection.
"""
disconnect(ib::Connection) = close(ib.socket)

end
