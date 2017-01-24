

function slidingwindow{T<:Number,U<:Number,S}(t::Vector{T},
                                              x::Vector{U},
                                              max_error::AbstractFloat,
                                              segment_construct::Function,
                                              ::Type{S}=LinearSegment{T,U}; # segment type
                                              loss_metric::Function=L₂,
                                              anchor::Integer=1,
                                              return_points::Bool=false)
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
    if return_points
        return pointseries(o, check=false)
    end
    o
end
export slidingwindow


function slidingwindow_interpolation{T<:Number,U<:Number}(
                                    t::Vector{T}, x::Vector{U},
                                    max_error::AbstractFloat;
                                    loss_metric::Function=L₂,
                                    anchor::Integer=1,
                                    return_points::Bool=false)
    slidingwindow(t, x, max_error, LinearSegmentInterpolation, LinearSegment{T,U},
                  loss_metric=loss_metric, anchor=anchor, return_points=return_points)
end
export slidingwindow_interpolation


function slidingwindow_regression{T<:Number,U<:Number}(
                                    t::Vector{T}, x::Vector{U},
                                    max_error::AbstractFloat;
                                    loss_metric::Function=L₂,
                                    anchor::Integer=1,
                                    return_points::Bool=false)
    slidingwindow(t, x, max_error, LinearSegmentRegression, LinearSegment{T,U},
                  loss_metric=loss_metric, anchor=anchor, return_points=return_points)
end
export slidingwindow_regression



