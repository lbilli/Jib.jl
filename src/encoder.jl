"""
    Encoder()

Wrap a buffer holding the outbound message
"""
struct Encoder
  buf::IOBuffer
end


"""
    (e::Encoder)(::T)

Define various encodings for known types
"""
(e::Encoder)(::T) where T = error("unknown Type: $T")

(e::Encoder)(x::Union{AbstractString,Int,Symbol}) = print(e.buf, x, '\0')

(e::Encoder)(x::Float64) = x == Inf ? e("Infinity") : print(e.buf, x, '\0')

(e::Encoder)(::Nothing) = e("")

(e::Encoder)(x::Bool) = e(x ? "1" : "0")

# Enums
(e::Encoder)(x::Enum{Int32}) = e(Int(x))

# NamedTuples
function (e::Encoder)(x::NamedTuple)

  for (n, v) ∈ pairs(x)
    v isa Union{AbstractString,Int,Float64} ||
      @warn "unsupported Type in NamedTuple" n v T=typeof(v)

    print(e.buf, n, '=', v, ';')
  end

  print(e.buf, '\0')
end

# Condition Types
(e::Encoder)(x::AbstractCondition{E}) where E = e(E, splat(x))

# Generators, as returned by splat()
(e::Encoder)(x::Base.Generator) = foreach(e, x)

# Multiple arguments
(e::Encoder)(x...) = foreach(e, x)
