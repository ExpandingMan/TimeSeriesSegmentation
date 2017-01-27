# TimeSeriesSegmentation
This package implements some basic time series segmentation algorithms.  It is compatible
with the "TimeSeries.jl" package.  Results are provided using the `SegmentSeries` type, 
which is useful for easily dealing with discontinuous functions and easily computing
properties of the segments themselves.

A glance at the source code of this package may reveal it to be unexpectedly complicated.
This is because there are three things that it deals with which are rather a huge headache:
* Time series with non-regular intervals.
* The functions resulting from the segmentation are in general discontinuous.
* Conversion to and from `DateTime`.

So far I haven't gone crazy trying to make this package computationally efficient, 
but for the most part it seems pretty performant.


## Using the Segmentation Algorithms
The following algorithms are currently available
* `slidingwindow_interpolation`, `slidingwindow_regression`
* `topdown_interpolation`, `topdown_regression`
* `bottomup_interpolation`, `bottomup_regression`
* `bottomup_stocahstic_interpolation`, `bottomup_stochastic_regression`

`_interpolation` or `_regression` denotes whether the segments generated will be determined
by linearly interpolating between endpoints, or performing a least-squares linear regression.
The latter is obviously more accurate (roughly speaking) but in general results in 
piecewise continuous functions.

To invoke one of these algorithms on a `TimeArray` (see 
[TimeSeries.jl](https://github.com/JuliaStats/TimeSeries.jl)) one can simply do, for example
```julia
ss = bottomup_regression(ts, Day, max_error, loss_metric=L₁)
```
Here `ts` is a `TimeArray` and `ss` is the resulting `SegmentSeries` object.  The second 
argument (in this case `Day`) is the period of time (a subtype of `Dates.Period`) which
is to be considered a unit of `1.0`.  For example, the sequence `[Date(3147, 1, 1),
Date(3147, 1, 2), Date(3147, 1, 3)]` converted to floats using `Hour` would be
`[0.0, 24.0, 48.0]`.  The parameter `max_error` determines the maximum error of a segment
produced by the algorithm.  The `loss_metric` parameter is the function which should be
used to determine the error. `L₁, L₂, LInfty` are exported by this package.

### The Stochastic Bottom-Up Algorithm
The `bottomup_stochastic` algorithm is similar to the bottomup algorithm except instead
or merging the segments that most reduce the total error on each iteration, it merges
a random pair of segments the merger of which produces a segment with error less than
the maximum error.  This can be useful for producing multiple different segmentations from
the same series with the total error of the segmentation approximation still being controlled.
This may be useful in cases where the segmentation is being used as a training dataset for
machine learning.  Note that the `bottomup_stochastic` algorithm uses the Julia `rand`
function so its seed can be set using `TimeSeriesSegmentation.srand`.


## `SegmentSeries`
The `SegmentSeries` type contains a vector of `LinearSegment` objects which simply
specify the end-points of each segment.  Note that a `SegmentSeries` in general describes
only a piecewise-continuous function, so it is not always trivial to convert them into
another time series.  Several useful functions are available when dealing with 
`SegmentSeries`.  If the series was produced by one of the segmentation algorithms called
on a `TimeArray`, the `SegmentSeries` can be easily converted back into a `TimeArray` using
```julia
tsPrime = TimeArray(ss)
```
If the `SegmentSeries` is discontinuous, the interpolation between points in the resulting
`TimeArray` will be a continuous approximation (i.e. discontinuities will be replaced with
line segments with an appropriately large slope).  One can also do
```julia
slope(ss)  # this returns a `Vector{Float64}` with the slope of each segment
intercept(ss) # this returns a `Vector{Float64}` with the y-intercept of each segment
getfunction(ss) # this returns the segment series as a piecewise-continuous Julia function
```


## Example
To run a complete example, one can include `"test/sunspotdata/import.jl` and use the
function `get_sunspot_daily_ts(:SpotsTotal)` (currently the segmentation algorithms only
support 1-dimensional time series).  What follows is a complete example of segmenting
the sunspots data
```julia
ts = get_sunspot_daily_ts(:SpotsTotal)
ts = from(ts, Date(1974, 1, 1)) # no missing data beyond this point

ss = bottomup_regression(ts, Day, 1.0e6)

ts_segmented = TimeArray(ss) # this can now be plotted along with ts
```

