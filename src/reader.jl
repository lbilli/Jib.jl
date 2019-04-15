module Reader

using Sockets

using ..Client: Connection, Core.read_one

import ..Wrapper

include("decoder.jl")


function read_msg(socket::TCPSocket)

  msg = read_one(socket)

  @assert length(msg) > 1 && msg[1] != msg[end] == 0x00

  split(String(msg[1:end-1]), '\0')
end


"""
  Process one message. Blocking.

"""
function check_msg(ib::Connection, w::Wrapper)

  msg = read_msg(ib.socket)

  Decoder.decode(msg, w, ib.version)

end

"""
  Process all messages waiting in queue without blocking

"""
function check_all(ib::Connection, w::Wrapper, flush::Bool=false)

  count = 0
  while bytesavailable(ib.socket) > 0 || ib.socket.status == Sockets.StatusOpen # =3

    msg = read_msg(ib.socket)

    flush || Decoder.decode(msg, w, ib.version)

    count += 1
  end

  count
end


function start_reader(ib::Connection, w::Wrapper)

  @async begin
            try
              while true
                check_msg(ib, w)
              end

            catch e

              e isa EOFError && @warn "Connection Terminated"
              println(e)
            end

            @info "Reader Exiting"
          end
end

end
