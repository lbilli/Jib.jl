abstract type AbstractCondition{T} end

struct ConditionPrice <: AbstractCondition{PRICE}
  conjunction::String
  is_more::Bool
  value::Float64
  conId::Int
  exchange::String
  triggerMethod::Int
end

struct ConditionTime <: AbstractCondition{TIME}
  conjunction::String
  is_more::Bool
  value::String
end

struct ConditionMargin <: AbstractCondition{MARGIN}
  conjunction::String
  is_more::Bool
  value::Int
end

struct ConditionExecution <: AbstractCondition{EXECUTION}
  conjunction::String
  secType::String
  exchange::String
  symbol::String
end

struct ConditionVolume <: AbstractCondition{VOLUME}
  conjunction::String
  is_more::Bool
  value::Int
  conId::Int
  exchange::String
end

struct ConditionPercentChange <: AbstractCondition{PERCENTCHANGE}
  conjunction::String
  is_more::Bool
  value::Float64
  conId::Int
  exchange::String
end


condition_map(t) = t === PRICE         ? ConditionPrice         :
                   t === TIME          ? ConditionTime          :
                   t === MARGIN        ? ConditionMargin        :
                   t === EXECUTION     ? ConditionExecution     :
                   t === VOLUME        ? ConditionVolume        :
                   t === PERCENTCHANGE ? ConditionPercentChange :
                   error("unknown condition type $t")
