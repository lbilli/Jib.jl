function Base.show(io::IO, ::MIME"text/plain", x::T) where T<:Union{Contract,ContractDetails,Order,OrderState,ScannerSubscription}

  for n ∈ fieldnames(T)
    v = getfield(x, n)

    println(io, n, "= ", something(v, "NA"))
  end
end
