isscalar(t) = haskey(decoders, t)
isprimitive(t) = isscalar(t) && t !== :string

wireassert(w, t) = w === 0x00 && t ∈ (:int32, :int64, :bool) || # VARINT
                   w === 0x01 && t === :double               || # I64
                   w === 0x02                                || # LEN
                     error("wrong wire/type combination: $w $t")


struct Field
  id::UInt32
  name::Symbol
  type::Symbol
  repeated::Bool
  decode::Function
  encode::Function

  function Field(i, n, t, r)

    @assert i ≤ MAX_ID && i ∉ RESERVED_ID

    d = get(decoders, t, nothing)
    e = get(encoders, t, nothing)

    if isnothing(d)

      desc = get(POOL, t, nothing)

      isnothing(desc) && error("unknown type: ", t)

      d = buf -> decode(desc, buf)

      e = function(buf, v, id)

            @assert v.desc === desc

            encode(buf, v, id)
          end
    end

    @assert !isnothing(e)

    new(i, n, t, r, d, e)
  end
end


struct Descriptor
  name::Symbol
  fields::Vector{Field}
  idmap::Dict{UInt32,Int}
  namemap::Dict{Symbol,Int}

  Descriptor(name, fields) = new(name, fields,
                                 Dict(v.id => i   for (i, v) ∈ pairs(fields)),
                                 Dict(v.name => i for (i, v) ∈ pairs(fields)))
end

Base.getindex(desc::Descriptor, id::UInt32) = desc.fields[desc.idmap[id]]
Base.getindex(desc::Descriptor, name::Symbol) = desc.fields[desc.namemap[name]]


struct Message
  desc::Descriptor
  data::Dict{Symbol,Any}

  function Message(desc::Descriptor, data)

    for (name, v) ∈ data

      fld = desc[name]

      @assert isvalid(fld, v)
    end

    new(desc, data)
  end
end

Message(desc::Symbol; kw...) = Message(POOL[desc], Dict{Symbol,Any}(kw...))


isvalid(fld, v::Vector{T}) where T =
  fld.repeated && !isempty(v) && xor(isscalar(fld.type), T === Message)

isvalid(fld, v::T) where T = !fld.repeated && xor(isscalar(fld.type), T === Message)

Base.getindex(m::Message, name) = getindex(m.data, name)

function Base.setindex!(m::Message, v, name)

  fld = m.desc[name]

  @assert isvalid(fld, v)

  setindex!(m.data, v, name)
end

Base.get(m::Message, name, default) = get(m.data, name, default)

Base.length(m::Message) = length(m.data)

has(m::Message, name) = haskey(m.data, name)

allnames(desc::Descriptor) = ( f.name for f ∈ desc.fields )
allnames(m::Message) = allnames(m.desc)

