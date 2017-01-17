

L₁{T<:Number}(x::Vector{T}) = sum(abs.(x))
L₂{T<:Number}(x::Vector{T}) = sum(x.^2)
L₃{T<:Number}(x::Vector{T}) = sum(abs.(x.^3))
L₄{T<:Number}(x::Vector{T}) = sum(abs.(x.^4))
LOrder{T<:Number}(order::Integer, x::Vector{T}) = sum(abs.(x.^order))
LInfty{T<:Number}(x::Vector{T}) = maximum(x)
export L₁, L₂, L₂, L₃, L₄, LOrder, LInfty




"""
    linear_interpolation(x, y)

Returns a function which is a linear interpolation between the initial and final points
(x,y).
"""
function linear_interpolation{T<:Number, U<:Number}(x::Vector{T}, y::Vector{U})
    b = (y[end] - y[1])/(x[end] - x[1])
    a = (x[end]*y[1] - x[1]*y[end])/(x[end] - x[1])
    linear_func(ξ::Number) = b*ξ + a  # TODO consider making this take arrays by default
end


"""
    linear_regression(x, y)

Returns the linear function determined from the linear regression of (x, y) points.
Uses the `linreg` function in `Base`.
"""
function linear_regression{T<:Number, U<:Number}(x::Vector{T}, y::Vector{U})
    a, b = linreg(x, y)
    linear_func(ξ::Number) = b*ξ + a
end


# TODO consider changing names to specify linearity
"""
    segment_interpolation(t, x)

Creates a segment by interpolating between the initial and final (t, x) pairs.
"""
function segment_interpolation{T<:Number, U<:Number}(tin::Vector{T}, xin::Vector{U})
    t = [tin[1], tin[end]]
    x = [xin[1], xin[end]]
    t, x
end


# yes, linreg is called only once in a loop
"""
    segment_regression(t, x)

Creates a segment by performing a least-squares linear regression on the provided points.
"""
function segment_regression{T<:Number, U<:Number}(tin::Vector{T}, xin::Vector{U})
    lin_func = linear_regression(tin, xin)
    t = [tin[1], tin[end]]
    x = [lin_func(tin[1]), lin_func(tin[end])]
    t, x
end


"""
    error_linear(tseg, xseg, t, x[, err_func=L₂])

Computes the linear interpolation error according to metric `err_func` between the 
segment given by `tseg`, `xseg` and the points (t, x).

Note that this can be used for any method of linear interpolation (i.e. either endpoint
interpolation or regression) if it is given the appropriate segment.
"""
function error_linear{T<:Number, U<:Number}(tseg::Vector{T}, xseg::Vector{U},
                                            t::Vector{T}, x::Vector{U},
                                            err_func::Function=L₂)
    f = linear_interpolation(tseg, xseg)
    err = x - f.(t)
    err_func(err)
end


"""
    join_continuous(seg1, seg2)

Joins two vectors in a manner appropriate for a continuous series.

The join operates on the first segment.
"""
function join_continuous!{T<:Number}(seg1::Vector{T}, seg2::Vector{T})
    (length(seg1) > 0) && pop!(seg1)
    append!(seg1, seg2)
end


"""
    join_discontinuous(t, x)

Joins two vectors in a manner appropriate for a (possibly) discontinuous series.

The join operates on the first segmend.
"""
function join_discontinuous!{T<:Number}(seg1::Vector{T}, seg2::Vector{T})
    append!(seg1, seg2)
end

