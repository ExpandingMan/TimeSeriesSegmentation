using TimeSeries
using TimeSeriesSegmentation
TSS = TimeSeriesSegmentation
using Gadfly

include("sunspotdata/import.jl")

const PLOT_FILE = "plots/sunspots_daily_1.png"

const MAX_ERROR = 1.0e6

ts = get_sunspot_daily_ts(:SpotsTotal)

# try to cut off the part with missing data
ts = from(ts, Date(1974, 1, 1))
# NaN value is -1
ts = ts[find(ts["SpotsTotal"] .≥ 0)]


# @time ss = slidingwindow_interpolation(ts, Day, MAX_ERROR)
# @time ss = slidingwindow_regression(ts, Day, MAX_ERROR)
# @time ss = topdown_interpolation(ts, Day, MAX_ERROR)
# @time ss = topdown_regression(ts, Day, MAX_ERROR)
# @time ss = bottomup_interpolation(ts, Day, MAX_ERROR)
@time ss = bottomup_regression(ts, Day, MAX_ERROR)

f = getfunction(ss)
ts_segmented = TimeArray(ss)

tsTilde = fft(ts, Day)
ssTilde = fft(ss, length(ts))

l = trunc(Int64, length(tsTilde)/2)
ts_power = abs2.(tsTilde)[1:l]
ss_power = abs2.(ssTilde)[1:l]


l1 = layer(x=ts.timestamp, y=ts.values, Geom.point, 
           Theme(default_color=colorant"red"), order=1)
l2 = layer(x=ts_segmented.timestamp, y=ts_segmented.values, Geom.line,
           Theme(default_color=colorant"blue"), order=2)
p1 = plot(l1, l2, Guide.xlabel("t (Days)"), Guide.ylabel("SpotsTotal"))

Nview = 400
k = [(i-1)/ss[end].t1 for i ∈ 1:length(ts_power)]
l3 = layer(x=k[1:Nview], y=ts_power[1:Nview], Geom.line,
           Theme(default_color=colorant"red"), order=1)
l4 = layer(x=k[1:Nview], y=ss_power[1:Nview], Geom.line,
           Theme(default_color=colorant"blue"), order=2)
p2 = plot(l3, l4, Guide.xlabel("1/Day"), Guide.ylabel("Power"), Scale.y_log10)

o = vstack(p1, p2)

draw(PNG(PLOT_FILE, 1536px, 1024px), o)

