
#========================================================================================
    NOTE:
    Currently the way this is defined this will split into  two segments even with
    max_error → ∞.  This is not a bug!  But perhaps should be changed?
========================================================================================#

function _topdown{T<:Number,U<:Number,S}(t::Vector{T},
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
        ssl = _topdown(t[1:split_node], x[1:split_node], max_error, segment_construct,
                       S, loss_metric=loss_metric)
    else
        ssl = SegmentSeries{S}([lseg_best], segment_construct)
    end

    if least_loss_r > max_error
        ssr = _topdown(t[split_node:end], x[split_node:end], max_error, segment_construct,
                       S, loss_metric=loss_metric)
    else
        ssr = SegmentSeries{S}([rseg_best], segment_construct)
    end

    append!(ssl, ssr)

    ssl
end

# this is to keep the interface consistent with other methods, because of return_points
function topdown{T<:Number,U<:Number,S}(t::Vector{T}, x::Vector{U}, max_error::AbstractFloat,
                                        segment_construct::Function, 
                                        ::Type{S}=LinearSegment{T,U};
                                        loss_metric::Function=L₂,
                                        return_points::Bool=false)
    o = _topdown(t, x, max_error, segment_construct, S, loss_metric=loss_metric)
    if return_points
        return pointseries(o, check=false)
    end
    o
end
export topdown


function topdown_interpolation{T<:Number,U<:Number}(t::Vector{T}, x::Vector{U},
                                                    max_error::AbstractFloat;
                                                    loss_metric::Function=L₂,
                                                    return_points::Bool=false)
    topdown(t, x, max_error, LinearSegmentInterpolation, LinearSegment{T,U},
            loss_metric=loss_metric, return_points=return_points)
end
export topdown_interpolation


function topdown_regression{T<:Number,U<:Number}(t::Vector{T}, x::Vector{U},
                                                 max_error::AbstractFloat;
                                                 loss_metric::Function=L₂,
                                                 return_points::Bool=false)
    topdown(t, x, max_error, LinearSegmentRegression, LinearSegment{T,U},
            loss_metric=loss_metric, return_points=return_points)
end
export topdown_regression

