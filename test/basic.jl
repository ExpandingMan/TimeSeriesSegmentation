using TimeSeries
using Gadfly
using TimeSeriesSegmentation
TSS = TimeSeriesSegmentation

const PLOT_FILE = "plots/basic_test_1.png"

const N = 50
const SEED = 999

srand(SEED)

t = collect(1.0:Float64(N))
x = randn(N)


info("running...")
# @time ss = slidingwindow_interpolation(t, x, 10.0)
# @time ss = slidingwindow_regression(t, x, 10.0)
# @time ss = topdown_interpolation(t, x, 10.0)
# @time ss = topdown_regression(t, x, 10.0)
# @time ss = bottomup_interpolation(t, x, 10.0)
# @time ss = bottomup_regression(t, x, 5.0)
@time ss = bottomup_stochastic_regression(t, x, 1.0)
info("done.")

f = getfunction(ss)
tPrime, xPrime = pointseries(ss)

l1 = layer(x=t, y=x, Geom.point, Geom.line,
           Theme(default_color=colorant"red"))
l2 = layer(x=tPrime, y=xPrime, Geom.point, Geom.line)
# l2 = layer(f, 1.0, 100.0)
p = plot(l2, l1, Guide.xlabel("t"), Guide.ylabel("x"))
draw(PNG(PLOT_FILE, 1536px, 1024px), p)



