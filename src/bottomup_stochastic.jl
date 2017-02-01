

"""
    bottomup_stochastic(t, x, max_error, segment_construct, segment_type=LinearSegment
                        [; loss_metric=L₂])
            
Generates a segment series from the time series `t, x` using the stochastic bottom-up 
algorithm with maximum error `max_error`.  Segments will be constructed using the function
`segment_construct`, i.e. usually this is either `LinearSegmentInterpolation` or 
`LinearSegmentRegression`.  The segment produced by this function must be of type
`segment_type` (one should always use the default value until non-linear segments are
implemented).
"""
function bottomup_stochastic{T<:Number,U<:Number,S}(t::Vector{T}, x::Vector{U},
                                                    max_error::AbstractFloat,
                                                    segment_construct::Function,
                                                    ::Type{S}=LinearSegment{T,U};
                                                    loss_metric::Function=L₂)
    ss = SegmentSeries(t, x, segment_construct)
    ranges = [(i, i+1) for i ∈ 1:length(ss)]

    merge_costs = Vector{Float64}(length(ss))
    merge_segs = Vector{S}(length(ss))
    for i ∈ 1:length(ss)
        _compute_merge_cost!(ss, i, t, x, ranges, merge_segs, merge_costs,
                             segment_construct, loss_metric)
    end

    lowloss_idx = [i for i ∈ 1:length(merge_costs) if merge_costs[i] < max_error]
    if length(lowloss_idx) == 0
        return ss
    end
    rand_idx = rand(lowloss_idx)
    rand_cost = merge_costs[rand_idx]
    min_cost, min_idx = findmin(merge_costs)

    while min_cost < max_error && length(ss) > 1
        idx_l = ranges[rand_idx][1]
        idx_r = ranges[rand_idx+1][2]  # this should always work because we merged with next
        deleteat!(ss, rand_idx+1)
        deleteat!(ranges, rand_idx+1)
        ss[rand_idx] = merge_segs[rand_idx]
        ranges[rand_idx] = (idx_l, idx_r)
        # **New series has been established**
        deleteat!(merge_costs, rand_idx+1)
        deleteat!(merge_segs, rand_idx+1)
        if rand_idx > 1
            _compute_merge_cost!(ss, rand_idx-1, t, x, ranges, merge_segs, merge_costs,
                                 segment_construct, loss_metric)
        end
        if rand_idx ≤ length(ss)
            _compute_merge_cost!(ss, rand_idx, t, x, ranges, merge_segs, merge_costs,
                                 segment_construct, loss_metric)
        end
        # the following line is slightly slower, but easier to understand
        # lowloss_idx = [i for i ∈ 1:length(merge_costs) if merge_costs[i] < max_error]
        # the following line is faster, only searches part of merge_costs
        lowloss_idx = _update_lowloss_idx(lowloss_idx, merge_costs, rand_idx, max_error)
        if length(lowloss_idx) == 0
            return ss
        end
        rand_idx = rand(lowloss_idx)
        rand_cost = merge_costs[rand_idx]
        min_cost, min_idx = findmin(merge_costs)
    end
    ss
end
export bottomup_stochastic


function _update_lowloss_idx(lowloss_idx::Vector, merge_costs::Vector, rand_idx::Integer,
                             max_error::AbstractFloat)
    idx = max(rand_idx-1, 1)
    badbeyond = searchsortedfirst(lowloss_idx, idx) 
    left_half = lowloss_idx[1:(badbeyond-1)]
    if length(left_half) == 0
        left_idx = 1
    else
        left_idx = left_half[end] + 1
    end
    right_half = [i for i ∈ left_idx:length(merge_costs) if merge_costs[i] < max_error]
    [left_half; right_half]
end



"""
    bottomup_stochastic_interpolation(t, x, max_error[; loss_metric=L₂]) 
    bottomup_stochastic_interpolation(ts, units, max_error[; loss_metric=L₂])
                    
Generates a segment series from the time series `t, x` using the stochastic bottom-up 
algorithm, generating segments using linear interpolation between end-points and with 
maximum error `max_error`.  The loss metric `loss_metric` will be used to evaluate error.

Alternatively one can pass a `TimeArray` object directly, in which case one must also 
specify the units of the resulting segment series (i.e. what period of time should correspond
to 1.0).
"""
function bottomup_stochastic_interpolation{T<:Number,U<:Number}(
                                                    t::Vector{T}, x::Vector{U},
                                                    max_error::AbstractFloat;
                                                    loss_metric::Function=L₂)
    bottomup_stochastic(t, x, max_error, LinearSegmentInterpolation, LinearSegment{T,U},
                        loss_metric=loss_metric)
end
function bottomup_stochastic_interpolation{T,U<:Number,N,D,A<:Vector}(
                                                        ts::TimeArray{U,N,D,A},
                                                        ::Type{T},
                                                        max_error::AbstractFloat;
                                                        loss_metric::Function=L₂,
                                                        return_timearray::Bool=false)
    t, x = convertaxis(T, ts)
    ss = bottomup_stochastic_interpolation(t, x, max_error, loss_metric=loss_metric)
    ss.units = T
    ss.zero = ts.timestamp[1]
    if return_timearray
        f = getfunction(ss)
        return TimeArray(ss.units, t, f.(t), ss.zero)
    end
    ss
end
export bottomup_stochastic_interpolation


"""
    bottomup_stochastic_regression(t, x, max_error[; loss_metric=L₂]) 
    bottomup_stochastic_regression(ts, units, max_error[; loss_metric=L₂])
                    
Generates a segment series from the time series `t, x` using the stochastic bottom-up 
algorithm, generating segments using least-squares linear regression between end-points 
and with maximum error `max_error`.  The loss metric `loss_metric` will be used to evaluate 
error.  

Alternatively one can pass a `TimeArray` object directly, in which case one must also 
specify the units of the resulting segment series (i.e. what period of time should correspond
to 1.0).
"""
function bottomup_stochastic_regression{T<:Number,U<:Number}(
                                                t::Vector{T}, x::Vector{U},
                                                max_error::AbstractFloat;
                                                loss_metric::Function=L₂)
    bottomup_stochastic(t, x, max_error, LinearSegmentRegression, LinearSegment{T,U},
                        loss_metric=loss_metric)
end
function bottomup_stochastic_regression{T,U<:Number,N,D,A<:Vector}(
                                                        ts::TimeArray{U,N,D,A},
                                                        ::Type{T},
                                                        max_error::AbstractFloat;
                                                        loss_metric::Function=L₂,
                                                        return_timearray::Bool=false)
    t, x = convertaxis(T, ts)
    ss = bottomup_stochastic_regression(t, x, max_error, loss_metric=loss_metric)
    ss.units = T
    ss.zero = ts.timestamp[1]
    if return_timearray
        f = getfunction(ss)
        return TimeArray(ss.units, t, f.(t), ss.zero)
    end
    ss
end
export bottomup_stochastic_regression

