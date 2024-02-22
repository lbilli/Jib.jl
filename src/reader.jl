module Reader

using ..Client: Client, read_one

include("decode.jl")
include("field.jl")


function read_msg(socket)

  msg = read_one(socket)

  FieldIterator(String(msg))
end


"""
    check_msg(ib, wrap)

Process one message and dispatch the appropriate callback. **Blocking**.
"""
function check_msg(ib, w, Tab=Dict)

  it = read_msg(ib.socket)

  decode(it, w, ib.version, Tab)
end


"""
    check_all(ib, wrap, flush=false)

Process all messages waiting in the queue. **Not blocking**.
If `flush=true`, messages are read but callbacks are not dispatched.

Return number of messages processed.
"""
function check_all(ib, w, flush=false, Tab=Dict)

  count = 0
  while bytesavailable(ib.socket) > 0 || ib.socket.status == Base.StatusOpen # =3

    it = read_msg(ib.socket)

    flush || decode(it, w, ib.version, Tab)

    count += 1
  end

  count
end


"""
    start_reader(ib, wrap)

Start a new [`Task`](@ref) to process messages asynchronously.
"""
function start_reader(ib, w, Tab=Dict)

  @async  begin
            try
              while true
                check_msg(ib, w, Tab)
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
