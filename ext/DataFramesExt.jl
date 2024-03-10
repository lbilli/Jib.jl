module DataFramesExt

import InteractiveBrokers

using DataFrames

function InteractiveBrokers.Reader.fill_table(cols, n::Int, it, Tab::Type{<:DataFrame})

    df = Tab([k => Vector{T}(undef, n) for (k, T) ∈ pairs(cols)];
                   copycols=false)
  
    nr, nc = size(df)
  
    for r ∈ 1:nr, c ∈ 1:nc
      df[r, c] = InteractiveBrokers.Reader.pop(it)
    end
  
    df
  end

end