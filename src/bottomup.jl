
# TODO this might get screwed up if we have more segment types

# TODO might improve performance if we make array eltypes Any so things aren't getting
# shifted around in memory


"""
    bottomup(t, x, max_error, segment_construct, segment_type=LinearSegment
             [; loss_metric=L₂])
            
Generates a segment series from the time series `t, x` using the bottom-up algorithm
with maximum error `max_error`.  Segments will be constructed using the function
`segment_construct`, i.e. usually this is either `LinearSegmentInterpolation` or 
`LinearSegmentRegression`.  The segment produced by this function must be of type
`segment_type` (one should always use the default value until non-linear segments are
implemented).
"""
function bottomup{T<:Number,U<:Number,S}(t::Vector{T}, x::Vector{U},
                                         max_error::AbstractFloat,
                                         segment_construct::Function,
                                         ::Type{S}=LinearSegment{T,U};
                                         loss_metric::Function=L₂)
    ss = SegmentSeries(t, x, segment_construct)
    # store original index range for each segment
    ranges = [(i, i+1) for i ∈ 1:length(ss)]

    # initialize merge costs
    merge_costs = Vector{Float64}(length(ss))
    merge_segs = Vector{S}(length(ss))
    for i ∈ 1:length(ss)
        _compute_merge_cost!(ss, i, t, x, ranges, merge_segs, merge_costs,
                             segment_construct, loss_metric)
    end

    min_cost, min_idx = findmin(merge_costs)

    while min_cost < max_error && length(ss) > 1
        idx_l = ranges[min_idx][1]
        idx_r = ranges[min_idx+1][2]  # this should always work because we merged with next
        deleteat!(ss, min_idx+1)
        deleteat!(ranges, min_idx+1)
        ss[min_idx] = merge_segs[min_idx]
        ranges[min_idx] = (idx_l, idx_r)
        # **New series has been established**
        deleteat!(merge_costs, min_idx+1)
        deleteat!(merge_segs, min_idx+1)
        if min_idx > 1
            _compute_merge_cost!(ss, min_idx-1, t, x, ranges, merge_segs, merge_costs,
                                 segment_construct, loss_metric)
        end
        if min_idx ≤ length(ss)
            _compute_merge_cost!(ss, min_idx, t, x, ranges, merge_segs, merge_costs,
                                 segment_construct, loss_metric)
        end
        min_cost, min_idx = findmin(merge_costs)
    end
    ss
end
export bottomup


# helper function for bottomup
function _compute_merge_cost!{T<:Number,U<:Number}(ss::SegmentSeries, i::Integer,
                                                   t::Vector{T}, x::Vector{U},
                                                   ranges::Vector,
                                                   merge_segs::Vector,
                                                   merge_costs::Vector,
                                                   segment_construct::Function,
                                                   loss_metric::Function)
    if i == length(ss)  # default behavior if there's nothing to merge with
        seg, cost = ss[end], Inf
    else
        idx_l = ranges[i][1]
        idx_r = ranges[i+1][2]
        seg, cost = merge(ss[i:(i+1)], t[idx_l:idx_r], x[idx_l:idx_r],
                          segment_construct, loss_metric=loss_metric)
    end
    merge_segs[i] = seg
    merge_costs[i] = cost
    seg, cost
end


# this might belong in segments.jl but it's nice to have here
function merge{T<:Number,U<:Number,S}(ss::SegmentSeries{S}, t::Vector{T}, x::Vector{U},
                                      segment_construct::Function;
                                      loss_metric::Function=L₂)
    @assert length(ss) == 2 "Can only merge two segments."
    seg = segment_construct(t, x)
    err = loss(loss_metric, seg, t, x)
    seg, err
end
export merge

# TODO clean up all these damn methods with macros

"""
    bottomup_interpolation(t, x, max_error[; loss_metric=L₂]) 
    bottomup_interpolation(ts, units, max_error[; loss_metric=L₂])
                    
Generates a segment series from the time series `t, x` using the bottom-up algorithm,
generating segments using linear interpolation between end-points and with maximum error
`max_error`.  The loss metric `loss_metric` will be used to evaluate error.

Alternatively one can pass a `TimeArray` object directly, in which case one must also 
specify the units of the resulting segment series (i.e. what period of time should correspond
to 1.0).
"""
function bottomup_interpolation{T<:Number,U<:Number}(t::Vector{T}, x::Vector{U},
                                                     max_error::AbstractFloat;
                                                     loss_metric::Function=L₂)
    bottomup(t, x, max_error, LinearSegmentInterpolation, LinearSegment{T,U},
             loss_metric=loss_metric)
end
function bottomup_interpolation{T,U<:Number,N,D,A<:Vector}(ts::TimeArray{U,N,D,A},
                                                           ::Type{T},
                                                           max_error::AbstractFloat;
                                                           loss_metric::Function=L₂,
                                                           return_timearray::Bool=false)
    t, x = convertaxis(T, ts)
    ss = bottomup_interpolation(t, x, max_error, loss_metric=loss_metric)
    ss.units = T
    ss.zero = ts.timestamp[1]
    if return_timearray
        f = getfunction(ss)
        return TimeArray(ss.units, t, f.(t), ss.zero)
    end
    ss
end
export bottomup_interpolation


"""
    bottomup_regression(t, x, max_error[; loss_metric=L₂]) 
    bottomup_regression(ts, units, max_error[; loss_metric=L₂])
                    
Generates a segment series from the time series `t, x` using the bottom-up algorithm,
generating segments using least-squares linear regression between end-points and with 
maximum error `max_error`.  The loss metric `loss_metric` will be used to evaluate error.  

Alternatively one can pass a `TimeArray` object directly, in which case one must also 
specify the units of the resulting segment series (i.e. what period of time should correspond
to 1.0).
"""
function bottomup_regression{T<:Number,U<:Number}(t::Vector{T}, x::Vector{U},
                                                  max_error::AbstractFloat;
                                                  loss_metric::Function=L₂)
    bottomup(t, x, max_error, LinearSegmentRegression, LinearSegment{T,U},
             loss_metric=loss_metric)
end
function bottomup_regression{T,U<:Number,N,D,A<:Vector}(ts::TimeArray{U,N,D,A},
                                                        ::Type{T},
                                                        max_error::AbstractFloat;
                                                        loss_metric::Function=L₂,
                                                        return_timearray::Bool=false)
    t, x = convertaxis(T, ts)
    ss = bottomup_regression(t, x, max_error, loss_metric=loss_metric)
    ss.units = T
    ss.zero = ts.timestamp[1]
    if return_timearray
        f = getfunction(ss)
        return TimeArray(ss.units, t, f.(t), ss.zero)
    end
    ss
end
export bottomup_regression

