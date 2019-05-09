module Client

using Sockets:   TCPSocket
using TimeZones

include("core.jl")
include("versions.jl")

"""
    Connection()

Hold a connection to IB TWS or IBGateway.
"""
struct Connection
  socket::TCPSocket
  id::Int
  connectOptions::String
  version::Version
  time::ZonedDateTime
  servertz::TimeZone
end
Connection(socket, id, connectOptions, version, time) = Connection(socket,
                                                                   id,
                                                                   connectOptions,
                                                                   version,
                                                                   time,
                                                                   TimeZones.timezone(time))

end
