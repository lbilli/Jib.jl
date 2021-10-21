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
  if id  < 75 && id ∉ (3, 5, 10, 11, 17, 18, 21) ||
     id ∈ (10, 18) && ver < Client.SIZE_RULES
    pop(it)
  end

  f = get(process, id, nothing)

  if isnothing(f)
    @error "decoder: unknown message" id

  else
    try
      f(it, w, ver)
    catch e
      if e isa EOFError
        @error "decoder: reached end of message" id
      else
        rethrow()
      end
    end

    isempty(it) || @error "decoder: message not fully parsed" id ignored=collect(String, it)
  end
end

end
