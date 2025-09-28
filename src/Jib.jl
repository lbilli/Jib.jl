module Jib

using Sockets

# Load ProtoLite
include("../ProtoLite.jl/src/ProtoLite.jl"); using .ProtoLite: ProtoLite as PB

# Read proto files
PB.readprotodir(joinpath(@__DIR__, "..", "proto"))


include("client.jl")
include("enums.jl")
include("types.jl")
include("types_condition.jl")
include("types_mutable.jl")
include("types_private.jl")
include("wrapper.jl")
include("protoutils.jl")
include("reader.jl")          ; using .Reader: check_all, start_reader
include("utils.jl")


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
function connect(host, port, clientId, connectOptions::String="", optionalCapabilities::String="")

  s = Sockets.connect(host, port)

  # Init string
  m, M = Client.Version .|> (typemin, typemax) .|> Int

  buf = Client.buffer(true)
  print(buf, m == M ? "v$m" : "v$m..$M")
  isempty(connectOptions) || print(buf, ' ', connectOptions)

  # Handshake
  Client.write_one(s, buf)

  v, t = Client.read_init(s)

  @info "connected" v t

  m ≤ v ≤ M || error("unsupported version")

  ib = Connection(s, clientId, connectOptions, Client.Version(v), t)

  Requests.startApi(ib, clientId, optionalCapabilities)

  ib
end

function connect(port, clientId, connectOptions::String="", optionalCapabilities::String="")

  localip = getalladdrinfo("localhost")

  connect(localip[1], port, clientId, connectOptions, optionalCapabilities)
end


"""
    disconnect(ib)

Close the connection.
"""
disconnect(ib) = close(ib.socket)

end
