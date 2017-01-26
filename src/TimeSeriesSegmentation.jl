__precompile__(true)

module TimeSeriesSegmentation

using TimeSeries

import Base.start, Base.next, Base.done
import Base.eltype, Base.length, Base.endof
import Base.getindex, Base.setindex!, Base.insert!
import Base.push!, Base.append!, Base.deleteat!
import Base.vcat
import Base.convert

# TODO move fourier.jl to another package and remove these
import Base.fft

import TimeSeries.TimeArray

# when evaluating discontinuous segment series as time series, evaluation will occur
# this far away from the segment junctures by default
const DISCONTINUITY_δ = 100eps(Float32)


include("segments.jl")
include("slidingwindow.jl")
include("topdown.jl")
include("bottomup.jl")
include("timearray.jl")
include("fourier.jl") # to be moved elsewhere



end
