module InteractiveBrokers

using Sockets

include("client.jl")
include("enums.jl")
include("Errors.jl")
using .Errors

include("types.jl")
include("types_condition.jl")
include("types_mutable.jl")
include("types_private.jl")
include("wrapper.jl")
include("reader.jl")          ; using .Reader: check_all, start_reader
include("utils.jl")
include("TickTypes.jl")    ; using .TickTypes: tickname

"""
    Connection()

Hold a connection to IB TWS or IBGateway.
"""
struct Connection
  socket::TCPSocket
  id::Int
  connectOptions::String
  version::Client.Version
  time::String
end


include("requests.jl")        ; using .Requests

"""
    connect([host, ]port, clientId, connectOptions="", optionalCapabilities="")

Connect to host `host` on port `port` and set client ID `clientId`.

Return a [`Connection`](@ref).
"""
function connect(;host::IPAddr=getalladdrinfo("localhost")[1], port::Int=4002, clientId::Int=1, connectOptions::String="", optionalCapabilities::String="")

  s = Sockets.connect(host, port)

  # Init string
  m, M = Client.Version .|> (typemin, typemax) .|> Int

  buf = Client.buffer(true)
  print(buf, m == M ? "v$m" : "v$m..$M")
  isempty(connectOptions) || print(buf, ' ', connectOptions)

  # Handshake
  Client.write_one(s, buf)

  msg = Reader.read_msg(s)

  v, t = Reader.decode_init(msg)

  @info "connected" v t

  m ≤ v ≤ M || error("unsupported version")

  ib = Connection(s, clientId, connectOptions, Client.Version(v), t)

  Requests.startApi(ib, clientId, optionalCapabilities)

  ib
end

"""
    disconnect(ib)

Close the connection.
"""
disconnect(ib) = close(ib.socket)

end
