struct IbkrErrorMessage <: Exception
    id::Union{Int,Nothing}
    errorCode::Union{Int,Nothing}
    errorString::String
    advancedOrderRejectJson::String
end