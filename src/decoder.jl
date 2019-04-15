module Decoder

using Base.Iterators: take

using ...Client

include("field.jl")
include("process.jl")
include("ticktype.jl")

# Make a shortcut
pop = popfirst!

function decode(msg, w, ver)

  it = Iterators.Stateful(Field.(msg))

  # The first field is the message ID
  id::Int = pop(it)

  # The second field (version) is unused for id < 75 and != 3, 5, 11, 17
  if id  < 75 && id ∉ [3, 5, 11, 17]             ||
     id ==  3 && ver < Client.MARKET_CAP_PRICE   ||
     id ==  5 && ver < Client.ORDER_CONTAINER    ||
     id == 11 && ver < Client.LAST_LIQUIDITY     ||
     id == 17 && ver < Client.SYNT_REALTIME_BARS

    pop(it)
  end

  f = get(process, id, nothing)

  if f === nothing
    @warn "Decoder: unknown message" ID=id

  else
    try
      f(it, w, ver)
    catch e
      if e isa EOFError
        @warn "Decoder: reached end of message" ID=id
      else
        rethrow()
      end
    end

    isempty(it) || @warn "Decoder: messsage not fully parsed" ID=id
  end

end

end
