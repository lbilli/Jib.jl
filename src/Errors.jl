module Errors

export IbkrErrorMessage

struct IbkrErrorMessage <: Exception
    id::Union{Int,Nothing}
    errorTime::Int
    errorCode::Union{Int,Nothing}
    errorString::String
    advancedOrderRejectJson::String
end

end