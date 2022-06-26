using Base.Iterators: take

include("process.jl")
include("ticktype.jl")

# Make a shortcut
const pop = popfirst!

function decode(it, w, ver)

  # The first field is the message ID
  id::Int = pop(it)

  # The second field (version) is ignored for id < 75 and != 3, 5, 11, 17, 21
  if id  < 75 && id ∉ (3, 5, 10, 11, 17, 18, 21) ||
     id ∈ (10, 18) && ver < Client.SIZE_RULES
    pop(it)
  end

  f = get(process, id, nothing)

  if isnothing(f)
    @error "decode(): unknown message" id

  else
    try
      f(it, w, ver)
    catch e
      @error "decode(): exception caught" M=it.msg
      # Print stacktrace to stderr
      Base.display_error(Base.current_exceptions())
    end

    isempty(it) || @error "decode(): message not fully parsed" M=it.msg ignored=collect(String, it)
  end
end

