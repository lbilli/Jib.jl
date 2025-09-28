include("process.jl")
include("ticktype.jl")


function decode((msgid, msg), w, ver)

  handler = get(process, msgid, nothing)

  if isnothing(handler)
    @error "decode(): unknown message" I=msgid

  else
    try
      handler(msg, w, ver)
    catch e
      @error "decode(): exception caught" I=msgid M=msg
      # Print stacktrace to stderr
      Base.display_error(Base.current_exceptions())
    end

  end
end

