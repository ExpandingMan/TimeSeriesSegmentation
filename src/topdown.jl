
#========================================================================================
    NOTE:
    Currently the way this is defined this will split into  two segments even with
    max_error → ∞.  This is not a bug!  But perhaps should be changed?
========================================================================================#

"""
    topdown(t, x, max_error, segment_construct, segment_type=LinearSegment
            [; loss_metric=L₂])
            
Generates a segment series from the time series `t, x` using the top-down algorithm
with maximum error `max_error`.  Segments will be constructed using the function
`segment_construct`, i.e. usually this is either `LinearSegmentInterpolation` or 
`LinearSegmentRegression`.  The segment produced by this function must be of type
`segment_type` (one should always use the default value until non-linear segments are
implemented).
"""
function topdown{T<:Number,U<:Number,S}(t::Vector{T},
                                        x::Vector{U},
                                        max_error::AbstractFloat,
                                        segment_construct::Function,
                                        ::Type{S}=LinearSegment{T,U};
                                        loss_metric::Function=L₂)
    @assert length(t) == length(x) "Invalid time series axis."
    # if segment has reach minimum length, there's nothing to do but fit a line
    if length(t) ≤ 2
        return SegmentSeries{S}([segment_construct(t, x)], segment_construct)
    end
    least_loss_l = Inf
    least_loss_r = Inf
    split_node = 2
    lseg_best = nothing  # these should never get returned
    rseg_best = nothing
    for i ∈ 2:(length(t)-1)
        tl, xl = window(t, x, 1:i)
        tr, xr = window(t, x, i:endof(t))
        lseg = segment_construct(tl, xl)
        rseg = segment_construct(tr, xr)
        loss_l = loss(loss_metric, lseg, tl, xl)
        loss_r = loss(loss_metric, rseg, tr, xr)
        if loss_l + loss_r < least_loss_l + least_loss_r
            least_loss_l = loss_l
            least_loss_r = loss_r
            split_node = i
            lseg_best = lseg
            rseg_best = rseg
        end
    end

    if least_loss_l > max_error
        ssl = topdown(t[1:split_node], x[1:split_node], max_error, segment_construct,
                      S, loss_metric=loss_metric)
    else
        ssl = SegmentSeries{S}([lseg_best], segment_construct)
    end

    if least_loss_r > max_error
        ssr = topdown(t[split_node:end], x[split_node:end], max_error, segment_construct,
                      S, loss_metric=loss_metric)
    else
        ssr = SegmentSeries{S}([rseg_best], segment_construct)
    end

    append!(ssl, ssr)

    ssl
end


"""
    topdown_interpolation(t, x, max_error[; loss_metric=L₂]) 
    topdown_interpolation(ts, units, max_error[; loss_metric=L₂])
                    
Generates a segment series from the time series `t, x` using the top-down algorithm,
generating segments using linear interpolation between end-points and with maximum error
`max_error`.  The loss metric `loss_metric` will be used to evaluate error.

Alternatively one can pass a `TimeArray` object directly, in which case one must also 
specify the units of the resulting segment series (i.e. what period of time should correspond
to 1.0).
"""
function topdown_interpolation{T<:Number,U<:Number}(t::Vector{T}, x::Vector{U},
                                                    max_error::AbstractFloat;
                                                    loss_metric::Function=L₂)
    topdown(t, x, max_error, LinearSegmentInterpolation, LinearSegment{T,U},
            loss_metric=loss_metric)
end
function topdown_interpolation{T,U<:Number,N,D,A<:Vector}(ts::TimeArray{U,N,D,A},
                                                          ::Type{T},
                                                          max_error::AbstractFloat;
                                                          loss_metric::Function=L₂,
                                                          return_timearray::Bool=false)
    t, x = convertaxis(T, ts)
    ss = topdown_interpolation(t, x, max_error, loss_metric=loss_metric)
    ss.units = T
    ss.zero = ts.timestamp[1]
    if return_timearray
        f = getfunction(ss)
        return TimeArray(ss.units, t, f.(t), ss.zero)
    end
    ss
end
export topdown_interpolation


"""
    topdown_regression(t, x, max_error[; loss_metric=L₂]) 
    topdown_regression(ts, units, max_error[; loss_metric=L₂])
                    
Generates a segment series from the time series `t, x` using the top-down algorithm,
generating segments using least-squares linear regression between end-points and with 
maximum error `max_error`.  The loss metric `loss_metric` will be used to evaluate error.  

Alternatively one can pass a `TimeArray` object directly, in which case one must also 
specify the units of the resulting segment series (i.e. what period of time should correspond
to 1.0).
"""
function topdown_regression{T<:Number,U<:Number}(t::Vector{T}, x::Vector{U},
                                                 max_error::AbstractFloat;
                                                 loss_metric::Function=L₂)
    topdown(t, x, max_error, LinearSegmentRegression, LinearSegment{T,U},
            loss_metric=loss_metric)
end
function topdown_regression{T,U<:Number,N,D,A<:Vector}(ts::TimeArray{U,N,D,A},
                                                       ::Type{T},
                                                       max_error::AbstractFloat;
                                                       loss_metric::Function=L₂,
                                                       return_timearray::Bool=false)
    t, x = convertaxis(T, ts)
    ss = topdown_regression(t, x, max_error, loss_metric=loss_metric)
    ss.units = T
    ss.zero = ts.timestamp[1]
    if return_timearray
        f = getfunction(ss)
        return TimeArray(ss.units, t, f.(t), ss.zero)
    end
    ss
end
export topdown_regression

