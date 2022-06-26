"""
    FieldIterator(msg)

Stateful iterator over the fields of message `msg`.
Return [`Field`](@ref) wrapped substrings.
"""
mutable struct FieldIterator
  msg::String
  c::Int
  function FieldIterator(msg)
    @assert !isempty(msg) && msg[end] == '\0'
    new(msg, 1)
  end
end

Base.IteratorSize(::Type{FieldIterator}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{FieldIterator}) = Base.HasEltype()
Base.eltype(::Type{FieldIterator}) = Field
Base.isdone(it::FieldIterator) = it.c > ncodeunits(it.msg)

function Base.iterate(it::FieldIterator, s=nothing)

  idx = findnext(==('\0'), it.msg, it.c)
  isnothing(idx) && return nothing

  res = @inbounds Field(SubString(it.msg, it.c, prevind(it.msg, idx)))

  setfield!(it, :c, idx + 1)

  res, nothing
end

function Base.popfirst!(it::FieldIterator)

  x = iterate(it)

  isnothing(x) ? throw(EOFError()) : x[1]
end


"""
    Field()

Wrap inbound fields and define conversions to
`String`, `Int`, `Float64`, `Bool` and `Enums`.
"""
struct Field{T<:AbstractString}
  value::T
end

# String and Symbol
Base.convert(::Type{T}, x::Field) where T<:Union{String,Symbol} = T(x.value)

# Int
function Base.convert(::Type{Int}, x::Field)

  x.value ∈ ("", "2147483647", "9223372036854775807") ? nothing :   # typemax(Int32) typemax(Int64)
                                                        parse(Int, x.value)
end

# Float
function Base.convert(::Type{Float64}, x::Field)

  x.value ∈ ("", "1.7976931348623157E308") ? nothing :  # prevfloat(Inf)
                                             parse(Float64, x.value)
end

# Bool: allowed values "1", "0", "true", "false"
Base.convert(::Type{Bool}, x::Field) = parse(Bool, x.value)

# Enum
Base.convert(::Type{T}, x::Field) where T<:Enum{Int32} = T(convert(Int, x))
