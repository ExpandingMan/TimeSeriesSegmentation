using TimeSeries
using TimeSeriesSegmentation
TSS = TimeSeriesSegmentation

timestamps = [DateTime(3146, 7, 1) + Dates.Day(i) for i ∈ 1:10]

β = TimeArray(timestamps, collect(1:10))

t, x = TSS.convertaxis(Dates.Millisecond, β, DateTime(3146, 7, 3))


