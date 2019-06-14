module Reader

using ..Client: Connection, Core.read_one

import ..Wrapper

include("decoder.jl")


function read_msg(socket)

  msg = read_one(socket)

  # Assert and chop last null char
  @assert length(msg) > 1 && msg[1] != pop!(msg) == 0x00

  split(String(msg), '\0')
end


"""
    check_msg(ib, wrap)

Process one message and dispatch the appropriate callback. **Blocking**.
"""
function check_msg(ib::Connection, w::Wrapper)

  msg = read_msg(ib.socket)

  Decoder.decode(msg, w, ib.version)
end


"""
    check_all(ib, wrap, flush=false)

Process all messages waiting in the queue. **Not blocking**.
If `flush=true`, messages are read but callbacks are not dispatched.

Return number of messages processed.
"""
function check_all(ib::Connection, w::Wrapper, flush::Bool=false)

  count = 0
  while bytesavailable(ib.socket) > 0 || ib.socket.status == Base.StatusOpen # =3

    msg = read_msg(ib.socket)

    flush || Decoder.decode(msg, w, ib.version)

    count += 1
  end

  count
end


"""
    start_reader(ib, wrap)

Start a new [`Task`](@ref) to process messages asynchronously.
"""
function start_reader(ib::Connection, w::Wrapper)

  @async  begin
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
