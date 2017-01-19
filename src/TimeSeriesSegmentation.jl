__precompile__(true)

module TimeSeriesSegmentation

using TimeSeries




include("segments.jl")
include("slidingwindow.jl")
include("topdown.jl")
include("bottomup.jl")
include("timearray.jl")





end
