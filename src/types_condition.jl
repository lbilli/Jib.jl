abstract type AbstractCondition{T} end

struct ConditionPrice <: AbstractCondition{PRICE}
  conjunction::String
  isMore::Bool
  price::Float64
  conId::Int
  exchange::String
  triggerMethod::Int
end

struct ConditionTime <: AbstractCondition{TIME}
  conjunction::String
  isMore::Bool
  time::String
end

struct ConditionMargin <: AbstractCondition{MARGIN}
  conjunction::String
  isMore::Bool
  percent::Int
end

struct ConditionExecution <: AbstractCondition{EXECUTION}
  conjunction::String
  secType::String
  exchange::String
  symbol::String
end

struct ConditionVolume <: AbstractCondition{VOLUME}
  conjunction::String
  isMore::Bool
  volume::Int
  conId::Int
  exchange::String
end

struct ConditionPercentChange <: AbstractCondition{PERCENTCHANGE}
  conjunction::String
  isMore::Bool
  changePercent::Float64
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
