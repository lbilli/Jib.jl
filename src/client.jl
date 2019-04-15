module Client

using Sockets
using TimeZones

include("core.jl")
include("versions.jl")

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
