function from_ibtime(s)

  if length(s) == 17 && s[9] == '-'
    ZonedDateTime(DateTime(s, "yyyymmdd-HH:MM:SS"), TimeZones.utc_tz)

  elseif length(s) > 20 && s[9] == ' '

    tz = validatetz(s[19:end])

    ZonedDateTime(DateTime(s[1:17], "yyyymmdd HH:MM:SS"), tz)

  else
    error("Unknown format $s")
  end
end


"""
    validatetz(tz)

Try to infer the server time zone setting from the connection
timestamp string.
"""
function validatetz(tz)

  if tz ∈ ["UTC", "GMT"]
    TimeZones.utc_tz

  elseif tz ∈ ["EST", "EDT", "Eastern Standard Time"]
    tz"America/New_York"

  elseif tz ∈ ["CST", "CDT", "Central Standard Time"]
    tz"America/Chicago"

  elseif tz ∈ ["PST", "PDT"]
    tz"America/Los_Angeles"

  elseif tz ∈ ["CET", "CEST", "Central European Time"]
    tz"Europe/Paris"

  elseif tz ∈ ["BST", "British Summer Time", "Greenwich Mean Time"]
    tz"Europe/London"

  elseif tz ∈ ["EET", "EEST"]
    tz"Europe/Riga"

  elseif tz == "JST"
    tz"Asia/Tokyo"

  elseif tz == "HKT"
    tz"Asia/Hong_Kong"

  elseif tz == "SGT"
    tz"Asia/Singapore"

  elseif tz == "China Standard Time"
    tz"Asia/Shanghai"

  else
    error("Unknown TZ: $tz")
  end
end


function Base.show(io::IO, ::MIME"text/plain", x::T) where T<:Union{Contract,ContractDetails,Order,OrderState,ScannerSubscription}

  for n ∈ fieldnames(T)
    v = getfield(x, n)

    println(io, n, "= ", something(v, "NA"))
  end
end
