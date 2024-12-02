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
Base.eltype(::Type{FieldIterator}) = FieldIterator
Base.isdone(it::FieldIterator) = it.c > ncodeunits(it.msg)

# Noop
Base.iterate(it::FieldIterator, s=nothing) = it, nothing

function pop(it::FieldIterator)

  idx = findnext(==('\0'), it.msg, it.c)
  isnothing(idx) && throw(EOFError())

  res = @inbounds SubString(it.msg, it.c, prevind(it.msg, idx))

  it.c = idx + 1

  res
end

rest(it::FieldIterator) = Iterators.takewhile(!isempty, it)


# String and Symbol
Base.convert(::Type{T}, it::FieldIterator) where T<:Union{String,Symbol} = T(pop(it))

# Int
function Base.convert(::Type{Int}, it::FieldIterator)

  x = pop(it)

  x ∈ ("", "2147483647", "9223372036854775807") ? nothing :   # typemax(Int32) typemax(Int64)
                                                  parse(Int, x)
end

# Float
function Base.convert(::Type{Float64}, it::FieldIterator)

  x = pop(it)

  x ∈ ("", "1.7976931348623157E308") ? nothing :  # prevfloat(Inf)
                                       parse(Float64, x)
end

# Bool: allowed values "1", "0", "true", "false"
Base.convert(::Type{Bool}, it::FieldIterator) = parse(Bool, pop(it))

# Enum
Base.convert(::Type{T}, it::FieldIterator) where T<:Enum{Int32} = T(convert(Int, it))

# Mask
function Base.convert(T::Type{NamedTuple{M,NTuple{N,Bool}}}, it) where {M,N}

  x::Int = it

  a = digits(Bool, x, base=2, pad=N)

  length(a) == N || @error "convert(): failed unmasking" T x

  T(a)
end

# Vector
function Base.convert(::Type{Vector{T}}, it::FieldIterator) where T

  n::Int = it

  res = Vector{T}(undef, n)

  for i ∈ 1:n
    res[i] = it
  end

  res
end

# Vector{<:NamedTuple}
function Base.convert(::Type{Vector{T}}, it::FieldIterator) where T<:NamedTuple

  n::Int = it

  T[ T(it) for _ ∈ 1:n ]
end

# NamedTuple
function Base.convert(::Type{NamedTuple}, it::FieldIterator)

  n::Int = it

  (; (convert(Symbol, it) => convert(String, it) for _ ∈ 1:n)...)
end

# Condition
function Base.convert(::Type{AbstractCondition}, it::FieldIterator)

  c::ConditionType = it

  convert(condition_map(c), it)
end

# Struct
Base.convert(::Type{T}, it::FieldIterator) where T<:Union{AbstractCondition,
                                                          ComboLeg,
                                                          CommissionReport,
                                                          DeltaNeutralContract,
                                                          IneligibilityReason,
                                                          OrderAllocation,
                                                          SoftDollarTier} =
                        T(slurp(fieldtypes(T), it)...)

# slurp
slurp(t, it) = convert.(t, Ref(it))

slurp!(x::T, idx, it) where T = for i ∈ idx  # Equivalent to setproperty!(x, sym, it)
                                  setfield!(x, i, convert(fieldtype(T, i), it))
                                end
