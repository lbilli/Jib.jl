using Base.Iterators: take

include("process.jl")

# Make a shortcut
const pop = popfirst!

function decode(it, w, ver, Tab=Dict)

  # The first field is the message ID
  id::Int = pop(it)

  # The second field (version) is ignored for id < 75 and != 3, 5, 10, 11, 17, 18, 21
  if id  < 75 && id ∉ (3, 5, 10, 11, 17, 18, 21)
    pop(it)
  end

  f = get(process, id, nothing)

  if isnothing(f)
    @error "decode(): unknown message" id
  else
    #try ---- COMMENTED FROM JIB
    f(it, w, ver, Tab)
    # catch e
    #   @error "decode(): exception caught" M=it.msg
    #   # Print stacktrace to stderr
    #   Base.display_error(Base.current_exceptions())
    # end

    isempty(it) || @error "decode(): message not fully parsed" M=it.msg ignored=collect(String, it)
  end
end

