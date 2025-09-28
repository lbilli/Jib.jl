transform(f, pb::PB.Message, name) = PB.has(pb, name) && (pb[name] = f(pb[name]))

todouble(pb::PB.Message, name) = transform(x -> parse(Float64, x), pb, name)
toint(pb::PB.Message, name) = transform(x -> parse(Int, x), pb, name)


function splat1(pb::PB.Message, names=PB.allnames(pb); kw...)

  ( (PB.has(pb, n) ? mapfrompb(pb[n]) : kw[n]) for n ∈ names )
end


mapfrompb(x) = x

function mapfrompb(pb::PB.Message)

  T = getproperty(@__MODULE__, pb.desc.name)

  convert(T, pb)
end


# Type map
# proto                      type
# DepthMarketDataDescription DepthMarketDataDescription
# FamilyCode                 FamilyCode
# Bar                        Bar
# HistoricalSession          HistoricalSession
# NewsProvider               NewsProvider
# PriceIncrement             PriceIncrement
# SmartComponent             SmartComponent
# SoftDollarTier             SoftDollarTier  (s)
# Tick*                      Tick*

# NamedTuple
function Base.convert(::Type{<:NamedTuple}, m::PB.Message)

  (; (n => m[n] for n ∈ PB.allnames(m))... )
end

# TagValue
function Base.convert(::Type{NamedTuple}, v::Vector{PB.Message})

  @assert v[1].desc.name === :TagValue

  (; (Symbol(m[:key]) => m[:value] for m ∈ v)...)
end


# Structs
function Base.convert(::Type{T}, m::PB.Message) where T<:Union{Contract,
                                                               ContractDetails,
                                                               Order,
                                                               OrderState}
  @assert nameof(T) === m.desc.name

  res = T()

  for (n, v) ∈ m.data

    setproperty!(res, n, v)
  end

  res
end


function Base.convert(::Type{T}, m::PB.Message) where T<:Union{DeltaNeutralContract,
                                                               IneligibilityReason,
                                                               SoftDollarTier}
  @assert nameof(T) === m.desc.name

  T((m[n] for n ∈ fieldnames(T))...)
end

# ComboLeg
Base.convert(::Type{ComboLeg}, m::PB.Message) = ComboLeg(splat1(m, fieldnames(ComboLeg); designatedLocation="")...)

# OrderAllocation
Base.convert(::Type{OrderAllocation}, m::PB.Message) = OrderAllocation(splat1(m, fieldnames(OrderAllocation); isMonetary=false)...)

# AbstractCondition
function Base.convert(::Type{AbstractCondition}, m::PB.Message)

  @assert m.desc.name === :OrderCondition

  conj = m[:isConjunction] ? "a" : "o"

  Cond = condition_map(ConditionType(m[:type]))

  g = (k === :conjunction ? conj : m[k] for k ∈ fieldnames(Cond) if k !== :type)

  Cond(g...)
end


# Map to Message

# Skip fields
skip(x) = false
skip(::Nothing) = true
skip(x::Bool) = !x
skip(x::AbstractString) = isempty(x)
skip(x::Vector) = isempty(x)
skip(x::PB.Message) = length(x) == 0


# Fill in message from iterator
function maptopb!(m::PB.Message, it)

  for (n, v) ∈ it

    val = maptopb(v)

    skip(val) && continue

    m[n] = val
  end

  m
end


maptopb(x) = x


function maptopb(s::T, exclude=()) where T <: Union{ComboLeg,
                                                    Contract,
                                                    DeltaNeutralContract,
                                                    ExecutionFilter,
                                                    Order,
                                                    OrderCancel,
                                                    ScannerSubscription,
                                                    SoftDollarTier,
                                                    WshEventData}
  pb = PB.Message(nameof(T))

  it = (n => getfield(s, n) for n ∈ fieldnames(T) if n ∉ exclude)

  maptopb!(pb, it)
end


function maptopb(desc::Symbol; kw...)

  pb = PB.Message(desc)

  maptopb!(pb, pairs(kw))
end


function maptopb(cond::AbstractCondition{E}) where E

   pb = PB.Message(:OrderCondition;
                   type=          Int(E),
                   isConjunction= cond.conjunction == "a")

   it = (n => getfield(cond, n) for n ∈ fieldnames(typeof(cond)) if n !== :conjunction)

   maptopb!(pb, it)
end


maptopb(v::Vector{T}) where T <: Union{AbstractCondition,
                                       ComboLeg} =  [ maptopb(e) for e ∈ v ]


maptopb(tv::NamedTuple) =
  [ PB.Message(:TagValue; key=string(k), value=string(v)) for (k, v) ∈ pairs(tv) ]
