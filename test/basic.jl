using TimeSeries
using Gadfly
using TimeSeriesSegmentation
TSS = TimeSeriesSegmentation

const PLOT_FILE = "plots/basic_test_1.png"

const N = 100
const SEED = 999

srand(SEED)

t = collect(1.0:Float64(N))
x = randn(N)

t = t[1:5]
x = x[1:5]

errlog = open("errlog.txt", "w+")
redirect_stderr(errlog)


# this error deliberately creates a single segment atm
info("running...")
# @time tPrime, xPrime = TSS.sliding_window_interpolation(t, x, 2.0, L₁)
# @time tPrime, xPrime = TSS.sliding_window_regression(t, x, 1.0, L₁)
@time tPrime, xPrime = TSS.topdown_interpolation(t, x, 0.01, L₁)
info("done.")

l1 = layer(x=t, y=x, Geom.point, Geom.line,
           Theme(default_color=colorant"red"))
l2 = layer(x=tPrime, y=xPrime, Geom.point, Geom.line)
p = plot(l2, l1, Guide.xlabel("t"), Guide.ylabel("x"))
draw(PNG(PLOT_FILE, 1536px, 1024px), p)



