module InteractiveBrokers

using Sockets

include("client.jl")
include("enums.jl")
include("errors.jl")
include("types.jl")
include("types_condition.jl")
include("types_mutable.jl")
include("types_private.jl")
include("wrapper.jl")
include("reader.jl")          ; using .Reader: check_all, start_reader
include("utils.jl")
include("TickTypes.jl")

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

  res = collect(String, Reader.read_msg(s))

  @assert length(res) == 2

  @info "connected" V=res[1] T=res[2]

  v = parse(Int, res[1])
  m ≤ v ≤ M || error("unsupported version")

  ib = Connection(s, clientId, connectOptions, Client.Version(v), res[2])

  Requests.startApi(ib, clientId, optionalCapabilities)

  ib
end

"""
    disconnect(ib)

Close the connection.
"""
disconnect(ib) = close(ib.socket)

end
