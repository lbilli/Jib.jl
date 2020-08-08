module Decoder

using Base.Iterators: take

using ...Client

include("field.jl")
include("process.jl")
include("ticktype.jl")

# Make a shortcut
const pop = popfirst!

function decode(msg, w, ver)

  it = Iterators.Stateful(Field.(msg))

  # The first field is the message ID
  id::Int = pop(it)

  # The second field (version) is ignored for id < 75 and != 3, 5, 11, 17, 21
  if id  < 75 && id ∉ [3, 5, 11, 17, 21]             ||
     id ==  5 && ver < Client.ORDER_CONTAINER        ||
     id == 21 && ver < Client.PRICE_BASED_VOLATILITY
    pop(it)
  end

  f = get(process, id, nothing)

  if isnothing(f)
    @error "Decoder: unknown message" id

  else
    try
      f(it, w, ver)
    catch e
      if e isa EOFError
        @error "Decoder: reached end of message" id
      else
        rethrow()
      end
    end

    isempty(it) || @error "Decoder: messsage not fully parsed" id
  end
end

end
