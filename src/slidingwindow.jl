
# TODO add TimeArray functionality



# TODO experiment with different termination conditions, can create false last segments

# this is the core sliding window algorithm
function slidingwindow{T<:Number, U<:Number}(t::Vector{T},
                                             x::Vector{U},
                                             max_error::AbstractFloat, 
                                             segment_func::Function,
                                             error_func::Function;
                                             segment_join::Function=join_discontinuous!,
                                             anchor::Integer=1)
    @assert length(t) == length(x) "Invalid time series axis."
    # it's not possible to know the size of these beforehand
    tout = Vector{T}(1)  # these are the output vectors
    xout = Vector{U}(1)
    tout[1] = t[anchor]  # initialize first element
    xout[1] = x[anchor]
    while (anchor + 1) ≤ length(t)
        i = 1
        tnow = t[anchor:(anchor+i)]
        xnow = x[anchor:(anchor+i)]
        (segt, segx) = segment_func(tnow, xnow)
        (prev_segt, prev_segx) = (segt, segx)
        while (anchor+i+1) ≤ length(t) && error_func(segt, segx, tnow, xnow) < max_error
            i += 1
            tnow = t[anchor:(anchor+i)]
            xnow = x[anchor:(anchor+i)]
            (prev_segt, prev_segx) = (segt, segx)
            (segt, segx) = segment_func(tnow, xnow)
        end
        segment_join(tout, prev_segt)
        segment_join(xout, prev_segx)
        i -= 1
        anchor += max(i, 1)  # not seeing how to get around this
    end
    tout, xout
end


# TODO consider changing the name of this to specify that it's linear
# this is the default setup of sliding window for linear interpolation
function slidingwindow_interpolation{T<:Number, U<:Number}(t::Vector{T},
                                     x::Vector{U},
                                     max_error::AbstractFloat,
                                     err_func::Function=L₂;
                                     segment_join::Function=join_continuous!,
                                     anchor::Integer=1)
    E(t1, x1, t2, x2) = error_linear(t1, x1, t2, x2, err_func)
    slidingwindow(t, x, max_error, segment_interpolation, E, anchor=anchor,
                  segment_join=segment_join)
end


function slidingwindow_regression{T<:Number, U<:Number}(t::Vector{T},
                                  x::Vector{U}, max_error::AbstractFloat,
                                  err_func::Function=L₂;
                                  segment_join::Function=join_discontinuous!,
                                  anchor=1)
    E(t1, x1, t2, x2) = error_linear(t1, x1, t2, x2, err_func)
    slidingwindow(t, x, max_error, segment_regression, E, anchor=anchor,
                  segment_join=segment_join)
end


# these methods use TimeArray as input

function slidingwindow{T<:Dates.Period,U,N,D,A}(
                       ::Type{T},
                       ta::TimeArray{U,N,D,A}, 
                       max_error::AbstractFloat,
                       segment_func::Function, error_func::Function,
                       t0::D=ta.timestamp[1];
                       segment_join::Function=join_discontinuous!,
                       anchor::Integer=1)
    t, x = convertaxis(T, ta, t0)
    tout, xout = slidingwindow(t, x, max_error, segment_func, error_func,
                               segment_join=sement_join, anchor=anchor)
    convertaxis(T, tout, xout, t0)
end

function slidingwindow_interpolation{T<:Dates.Period,U,N,D,A}(
                                     ::Type{T},
                                     ta::TimeArray{U,N,D,A},
                                     max_error::AbstractFloat,
                                     t0::D=ta.timestamp[1];
                                     err_func::Function=L₂,
                                     segment_join::Function=join_continuous!,
                                     anchor::Integer=1)
    E(t1, x1, t2, x2) = error_linear(t1, x1, t2, x2, err_func)
    slidingwindow(T, ta, max_error, segment_interpolation, E, t0,
                  segment_join=segment_join, anchor=anchor)
end

function slidingwindow_regression{T<:Dates.Period,U,N,D,A}(
                                  ::Type{T},
                                  ta::TimeArray{U,N,D,A},
                                  max_error::AbstractFloat,
                                  t0::D=ta.timestamp[1];
                                  err_func::Function=L₂,
                                  segment_join::Function=join_discontinuous!,
                                  anchor::Integer=1)
    E(t1, x1, t2, x2) = error_linear(t1, x1, t2, x2, err_func)
    slidingwindow(T, ta, max_error, segment_regression, E, t0,
                  segment_join=segment_join, anchor=anchor)
end

