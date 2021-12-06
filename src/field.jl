"""
    Field()

Wrap inbound fields and define conversions to
`String`, `Int`, `Float64`, `Bool` and `Enums`.
"""
struct Field{T<:AbstractString}
  value::T
end

# String
Base.convert(::Type{String}, x::Field) = String(x.value)

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
