const POOL = Dict{Symbol,Descriptor}()


function addtopool(d)

  haskey(POOL, d.name) &&
    @warn "overriding descriptor" D=d.name

  POOL[d.name] = d
end


function next(io)

  # Skip empty or comment line
  while !eof(io)

    line = readline(io)

    m = match(r"^\s*(//.*)?$", line)

    isnothing(m) && return line
  end

  nothing
end


function readproto(dir, fname, queue)

  io = open(joinpath(dir, fname))

  next(io) == """syntax = "proto3";""" ||
    error("readproto(): syntax statement expected: ", fname)

  while true

    line = next(io)

    isnothing(line) && break

    # Find imports
    m = match(r"^import \"(\S+)\";$", line)

    if !isnothing(m)
      imp = m.captures[1]

      while imp ∈ queue
#        @info "waiting" F=fname D=imp
        yield()
      end

      continue
    end

    m = match(r"^message (\S+) \{$", line)

    isnothing(m) && continue

    # New descriptor
    desc = Symbol(m.captures[1])
    fields = Field[]

    while true

      line = next(io)

      if line == "}"
        addtopool(Descriptor(desc, fields))
        break
      end

      m = match(r"^\s*(optional|repeated) (\S+) (\S+) = (\d+);$", line)

      isnothing(m) && error("readproto(): parsing error")

      push!(fields, Field(parse(Int, m.captures[4]),
                          Symbol(m.captures[3]),
                          Symbol(m.captures[2]),
                          m.captures[1] == "repeated"))
    end
  end

  fname ∈ queue ? delete!(queue, fname) :
                  @warn "not in queue" F=fname
end


function readprotodir(dir)

  fnames = filter(endswith(".proto"), readdir(dir))

  queue = Set(fnames)

  asyncmap(f -> readproto(dir, f, queue), fnames)

  isempty(queue) || @warn "queue not empty" Q=queue

end
