

"""
    slidingwindow(t, x, max_error, segment_construct, segment_type=LinearSegment
                  [; loss_metric=L₂, anchor=1])

Generates a segment series from the time series `t, x` using the sliding window algorithm
with maximum error `max_error`.  Segments will be constructed using the function
`segment_construct`, i.e. usually this is either `LinearSegmentInterpolation` or 
`LinearSegmentRegression`.  The segment produced by this function must be of type
`segment_type` (one should always use the default value until non-linear segments are
implemented).  The algorithm commences at index `anchor` in `t, x`, i.e. the resulting
segment series will start there.
"""
function slidingwindow{T<:Number,U<:Number,S}(t::Vector{T},
                                              x::Vector{U},
                                              max_error::AbstractFloat,
                                              segment_construct::Function,
                                              ::Type{S}=LinearSegment{T,U}; # segment type
                                              loss_metric::Function=L₂,
                                              anchor::Integer=1)
    @assert length(t) == length(x) "Invalid time series axis"
    o = SegmentSeries{S}(segment_construct)
    while anchor ≤ length(t) - 1
        i = 1
        tnow, xnow = window(t, x, anchor:(anchor+i))
        seg = segment_construct(tnow, xnow)  # initialize segment to check loss
        prev_seg = seg
        while loss(loss_metric, seg, tnow, xnow) < max_error
            i += 1
            prev_seg = seg
            if anchor+i > length(t)  # check if it's done because it hit the end
                break
            end
            tnow, xnow = window(t, x, anchor:(anchor+i))
            seg = segment_construct(tnow, xnow)
        end
        push!(o, prev_seg)
        i -= 1
        anchor += max(i, 1)
    end
    o
end
export slidingwindow


"""
    slidingwindow_interpolation(t, x, max_error[; loss_metric=L₂, anchor=1])
    slidingwindow_interpolation(ts, units, max_error[; loss_metric=L₂, anchor=1])
                    
Generates a segment series from the time series `t, x` using the sliding window algorithm,
generating segments using linear interpolation between end-points and with maximum error
`max_error`.  The loss metric `loss_metric` will be used to evaluate error.  The 
algorithm will start from index `anchor`.

Alternatively one can pass a `TimeArray` object directly, in which case one must also 
specify the units of the resulting segment series (i.e. what period of time should correspond
to 1.0).
"""
function slidingwindow_interpolation{T<:Number,U<:Number}(
                                    t::Vector{T}, x::Vector{U},
                                    max_error::AbstractFloat;
                                    loss_metric::Function=L₂,
                                    anchor::Integer=1)
    slidingwindow(t, x, max_error, LinearSegmentInterpolation, LinearSegment{T,U},
                  loss_metric=loss_metric, anchor=anchor)
end
function slidingwindow_interpolation{T,U<:Number,N,D,A<:Vector}(ts::TimeArray{U,N,D,A},
                                                                ::Type{T},
                                                                max_error::AbstractFloat;
                                                                loss_metric::Function=L₂,
                                                                anchor::Integer=1,
                                                                return_timearray::Bool=false)
    t, x = convertaxis(T, ts)
    ss = slidingwindow_interpolation(t, x, max_error, loss_metric=loss_metric, anchor=anchor)
    ss.units = T
    ss.zero = ts.timestamp[1]
    if return_timearray
        f = getfunction(ss)
        return TimeArray(ss.units, t, f.(t), ss.zero)
    end
    ss
end
export slidingwindow_interpolation


"""
    slidingwindow_regression(t, x, max_error[; loss_metric=L₂, anchor=1]) 
    slidingwindow_regression(ts, units, max_error[; loss_metric=L₂, anchor=1])
                    
Generates a segment series from the time series `t, x` using the sliding window algorithm,
generating segments using least-squares linear regression between end-points and with 
maximum error `max_error`.  The loss metric `loss_metric` will be used to evaluate error.  
The algorithm will commence from index `anchor`.

Alternatively one can pass a `TimeArray` object directly, in which case one must also 
specify the units of the resulting segment series (i.e. what period of time should correspond
to 1.0).
"""
function slidingwindow_regression{T<:Number,U<:Number}(
                                    t::Vector{T}, x::Vector{U},
                                    max_error::AbstractFloat;
                                    loss_metric::Function=L₂,
                                    anchor::Integer=1)
    slidingwindow(t, x, max_error, LinearSegmentRegression, LinearSegment{T,U},
                  loss_metric=loss_metric, anchor=anchor)
end
function slidingwindow_regression{T,U<:Number,N,D,A<:Vector}(ts::TimeArray{U,N,D,A},
                                                             ::Type{T},
                                                             max_error::AbstractFloat;
                                                             loss_metric::Function=L₂,
                                                             anchor::Integer=1,
                                                             return_timearray::Bool=false)
    t, x = convertaxis(T, ts)
    ss = slidingwindow_regression(t, x, max_error, loss_metric=loss_metric, anchor=anchor)
    ss.units = T
    ss.zero = ts.timestamp[1]
    if return_timearray
        f = getfunction(ss)
        return TimeArray(ss.units, t, f.(t), ss.zero)
    end
    ss
end
export slidingwindow_regression



