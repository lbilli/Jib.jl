using TimeZones

function from_ibtime(s::AbstractString)

  if length(s)==17 && s[9] == '-'
    ZonedDateTime(DateTime(s, "yyyymmdd-HH:MM:SS"), TimeZones.utc_tz)

  elseif length(s) > 20 && s[9] == ' '

    tz = infer_tz(s[19:end])

    ZonedDateTime(DateTime(s[1:17], "yyyymmdd HH:MM:SS"), tz)

  else
    error("Unknown format $s")
  end
end


function infer_tz(tz)

   if tz ∈ ["UTC", "GMT"]
     TimeZones.utc_tz

   elseif tz ∈ ["EST", "EDT", "Eastern Standard Time"]
     tz"America/New_York"

    elseif tz ∈ ["CET", "CEST"]
      tz"Europe/Paris"

    elseif tz ∈ ["BST", "British Summer Time", "Greenwich Mean Time"]
      tz"Europe/London"
    
    elseif tz ∈  ["PZT", "Pacific Standard Time]
      tz"America/Los_Angeles"

    else
      error("Unknown TZ: $tz")
    end
end


function Base.show(io::IO, x::T) where {T<:Union{Contract,ContractDetails,Order,OrderState,ScannerSubscription}}

  for n ∈ fieldnames(T)
    v = getfield(x, n)

    println("$n= ", something(v, "NA"))
  end
end
