__precompile__(true)

module TimeSeriesSegmentation

using TimeSeries

import Base.start, Base.next, Base.done
import Base.eltype, Base.length, Base.endof
import Base.getindex, Base.setindex!, Base.insert!
import Base.push!, Base.append!, Base.deleteat!
import Base.vcat



include("segments.jl")
include("slidingwindow.jl")
include("topdown.jl")
include("bottomup.jl")
include("timearray.jl")



end
