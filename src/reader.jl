module Reader

using ..Client: Client, read_one

include("decode.jl")


function read_msg(ib)

  msgid::Int, msg = read_one(ib.socket)

  @assert msgid > Client.PROTOBUF_MSG_ID

  msgid, msg
end


"""
    check_msg(ib, wrap)

Process one message and dispatch the appropriate callback. **Blocking**.
"""
function check_msg(ib, w)

  msg = read_msg(ib)

  decode(msg, w, ib.version)
end


"""
    check_all(ib, wrap, flush=false)

Process all messages waiting in the queue. **Not blocking**.
If `flush=true`, messages are read but callbacks are not dispatched.

Return number of messages processed.
"""
function check_all(ib, w, flush=false)

  count = 0
  while bytesavailable(ib.socket) > 0 || ib.socket.status == Base.StatusOpen # =3

    msg = read_msg(ib)

    flush || decode(msg, w, ib.version)

    count += 1
  end

  count
end


"""
    start_reader(ib, wrap)

Start a new [`Task`](@ref) to process messages asynchronously.
"""
function start_reader(ib, w)

  @async  begin
            try
              while true
                check_msg(ib, w)
              end

            catch e

              if e isa EOFError
                @warn "connection terminated"
              else
                @error "exception thrown" e
              end
            end

            @info "reader exiting"
          end
end

end
