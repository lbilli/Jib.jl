module Jib

using DataFrames,
      Sockets,
      TimeZones

include("client.jl")
include("enums.jl")
include("types.jl")
include("types_condition.jl")
include("types_mutable.jl")
include("types_private.jl")
include("wrapper.jl")
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
  time::ZonedDateTime
  servertz::TimeZone
end
Connection(socket, id, connectOptions, version, time) = Connection(socket,
                                                                   id,
                                                                   connectOptions,
                                                                   version,
                                                                   time,
                                                                   timezone(time))

include("requests.jl")        ; using .Requests

"""
    connect([host, ]port, clientId, connectOptions="", optionalCapabilities="")

Connect to host `host` on port `port` and set client ID `clientId`.

Return a [`Connection`](@ref).
"""
function connect(host, port, clientId, connectOptions::String="", optionalCapabilities::String="")

  s = Sockets.connect(host, port)

  # Init string
  m, M = Int(typemin(Client.Version)), Int(typemax(Client.Version))

  buf = Client.buffer(true)
  print(buf, m == M ? "v$m" : "v$m..$M")
  isempty(connectOptions) || print(buf, " ", connectOptions)

  # Handshake
  Client.write_one(s, buf)

  res = Reader.read_msg(s)

  @assert length(res) == 2

  @info "Connected" V=res[1] T=res[2]

  v = parse(Int, res[1])
  m ≤ v ≤ M || error("Unsupported version.")

  ib = Connection(s, clientId, connectOptions, Client.Version(v), from_ibtime(res[2]))

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
