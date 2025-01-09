include("process.jl")
include("fielditerator.jl")
include("TickTypes.jl")


function decode_init(msg)

  it = FieldIterator(msg)

  v::Int,
  t::String = it

  isempty(it) || @error "decode_init(): init message not fully parsed" M=msg

  v, t
end


function decode(msg, w, ver)

  it = FieldIterator(msg)

  # The first field is the message ID
  id::Int = it

  # The second field (version) is ignored for id < 75 and != 3, 4, 5, 10, 11, 17, 18, 21
  if id < 75 && id ∉ (3, 4, 5, 10, 11, 17, 18, 21) ||
     id == 4 && ver < Client.ERROR_TIME
    pop(it)
  end

  f = get(process, id, nothing)

  if isnothing(f)
    @error "decode(): unknown message" id
  else
    #try --- Commented from JIB
      f(it, w, ver)
    # catch e
    #   @error "decode(): exception caught" M=msg
    #   # Print stacktrace to stderr
    #   Base.display_error(Base.current_exceptions())
    # end

    isempty(it) || @error "decode(): message not fully parsed" M=msg ignored=collect(String, rest(it))
  end
end

