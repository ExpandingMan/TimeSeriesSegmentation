
# loss functions
L₁{T<:Number}(x::Vector{T}) = sum(abs.(x))
L₂{T<:Number}(x::Vector{T}) = sum(x.^2)
L₃{T<:Number}(x::Vector{T}) = sum(abs.(x.^3))
L₄{T<:Number}(x::Vector{T}) = sum(abs.(x.^4))
LOrder{T<:Number}(order::Integer, x::Vector{T}) = sum(abs.(x.^order))
LInfty{T<:Number}(x::Vector{T}) = maximum(x)
export L₁, L₂, L₂, L₃, L₄, LOrder, LInfty



abstract AbstractSegment <: Any
abstract AbstractSegmentSeries <: Any


"""
    type LinearSegment

A line segment.  This object simply stores the endpoints of a line segment in a 2-dimensional
space.
"""
type LinearSegment{T<:Number,U<:Number} <: AbstractSegment
    t0::T
    x0::U
    t1::T
    x1::U
end
export LinearSegment


"""
    type SegmentSeries

A series of segments.
"""
type SegmentSeries{S<:AbstractSegment} <: AbstractSegmentSeries
    segments::Vector{S}
    zero::DateTime
    units::DataType
    cont::Bool

    function SegmentSeries()
        o = new(Vector{S}(0), DateTime())
        o.cont = false
    end

    function SegmentSeries(segs::Vector{S}, segment_construct::Function)
        o = new(segs, DateTime())
        o.cont = continuous(segment_construct)
        o
    end

    function SegmentSeries(segment_construct::Function)
        o = new(Vector{S}(0), DateTime())
        o.cont = continuous(segment_construct)
        o
    end

    SegmentSeries(segs::Vector{S}) = new(segs, DateTime())

    function SegmentSeries(segs::Vector{S}, zero::DateTime, units::DataType,
                           cont::Bool)
        @assert units <: Dates.Period "Units must be of type `Dates.Period`."
        new(segs, zero, units, cont)
    end
end
export SegmentSeries


# creates a segment series out of a time series
# conversions from TimeArray are found in timearray.jl
function SegmentSeries{T<:Number,U<:Number}(t::Vector{T}, x::Vector{U}, 
                                            segment_construct::Function;
                                            units::Union{DataType,Void}=nothing,
                                            t0::DateTime=DateTime())
    segs = [segment_construct(t[i:(i+1)], x[i:(i+1)]) for i ∈ 1:(length(t)-1)]
    o = SegmentSeries{LinearSegment{T,U}}(segs, segment_construct)
    if units ≠ nothing
        @assert units <: Dates.Period "Units must be of type `Dates.Period`."
        o.units = units
    end
    o.zero = t0
    o
end

function SegmentSeries{T<:Number,U<:Number}(t::Vector{T}, x::Vector{U})
    SegmentSeries(t, x, LinearSegmentInterpolation)
end


# checks whether a segment series is continuous
function _ss_continuous(ss::AbstractSegmentSeries)
    tcont = [ss[i].t1 ≈ ss[i+1].t0 for i ∈ 1:(length(ss)-1)]
    if !prod(tcont)
        return false
    end
    xcont = [ss[i].x1 ≈ ss[i+1].t0 for i ∈ 1:(length(ss)-1)]
    if !prod(xcont)
        return false
    end
    true
end


# TODO add user modifiable segment constructor lists
"""
    continuous(segment_constructor)
    continuous(segment_series[; check=true])

Checks whether a segment constructor constructs segments that are guaranteed to be 
continuous if applied in the usual way.  Alternatively, checks whether a `SegmentSeries`
is continuous.  If `check` is true, a direct check of the continuity of the series will
be performed (this is inefficient).
"""
function continuous(segment_construct::Function)
    if segment_construct ∈ [LinearSegmentInterpolation]
        return true
    elseif segment_construct ∈ [LinearSegmentRegression]
        return false
    else
        throw(ArgumentError("Unrecognized segment constructor."))
    end
end
function continuous!(ss::AbstractSegmentSeries; check::Bool=true)
    if check || !isdefined(ss, :cont)
        ss.cont = _ss_continuous(ss)
    end
    ss.cont
end
export continuous, continuous!


#======================================================================================
    <SegmentSeries Interface>
======================================================================================#
start(ss::SegmentSeries) = 1
next(ss::SegmentSeries, state) = next(ss.segments, state)
done(ss::SegmentSeries, state) = done(ss.segments, state)
eltype(ss::SegmentSeries) = eltype(ss.segments)
length(ss::SegmentSeries) = length(ss.segments)
endof(ss::SegmentSeries) = endof(ss.segments)

getindex(ss::SegmentSeries, i::Integer) = getindex(ss.segments, i)
setindex!(ss::SegmentSeries, v, i::Integer) = setindex!(ss.segments, v, i)

deleteat!(ss::SegmentSeries, i) = deleteat!(ss.segments, i)
insert!(ss::SegmentSeries, i, v) = insert!(ss.segments, i, v)

# note this has to be defined separately from the Integer one to return a SegmentSeries
function getindex{S,T<:Integer}(ss::SegmentSeries{S}, r::UnitRange{T})
    o = SegmentSeries{S}(ss.segments[r])
    o.cont = ss.cont
    if isdefined(ss, :units)
        o.units = ss.units
    end
    o
end

push!{S}(ss::SegmentSeries{S}, items::S...) = push!(ss.segments, items...)

append!{S}(ss::SegmentSeries{S}, v::Vector{S}) = append!(ss.segments, v)

function append!{S}(ss::SegmentSeries{S}, s2::SegmentSeries{S})
    if isdefined(ss, :zero) && isdefined(s2, :zero)
        @assert ss.zero == s2.zero "SegmentSeries must have the same zero to concatenate."
    end
    if isdefined(ss, :units) && isdefined(s2, :units)
        @assert ss.units == s2.units "SegmentSeries must have same units to concatenate."
    end
    ss.cont = ss.cont && s2.cont
    append!(ss.segments, s2.segments)
end

function vcat{S}(ss::SegmentSeries{S}, s2::SegmentSeries{S})
    if isdefined(ss, :zero) && isdefined(s2, :zero)
        @assert ss.zero == s2.zero "SegmentSeries must have the same zero to concatenate."
    end
    if isdefined(ss, :units) && isdefined(s2, :units)
        @assert ss.units == s2.units "SegmentSeries must have same units to concatenate."
    end
    SegmentSeries(vcat(ss.segments, s2.segments), ss.zero, ss.units, ss.cont && s2.cont)
end

#======================================================================================
    </SegmentSeries Interface>
======================================================================================#

function _pointseries_continuous(ss::SegmentSeries)
    t = [s.t0 for s ∈ ss]
    push!(t, ss[end].t1)
    x = [s.x0 for s ∈ ss]
    push!(x, ss[end].x1)
    t, x
end

function _pointseries_discontinuous(ss::SegmentSeries)
    t = reduce(vcat, [s.t0, s.t1] for s ∈ ss)
    x = reduce(vcat, [s.x0, s.x1] for s ∈ ss)
    t, x
end

# TODO ideally δ would depend on the length of the segment series
function _pointseries_discontinuous_hack(ss::SegmentSeries, δ::AbstractFloat=DISCONTINUITY_δ)
    f = getfunction(ss)
    t = reduce(vcat, [ss[i].t0+δ, ss[i].t1-δ] for i ∈ 1:length(ss))
    x = f.(t)
    t, x
end

                                    

"""
    pointseries(ss[; check_continuity=false, δ=10eps(Float32), degenerate=false])

Converts a segment series to an ordinary time series.  If `check_continuity` the continuity 
of the time-series will be rigorously re-checked.  Note that the method by which the segment
series is joined to a series of points depends on whether it is continuous.  If it is
continuous, the segments will simply be joined one to the other such that there is a single
point between segments.  If it is discontinuous, it will be converted to a function and
evaluated at the segment junctions ±δ.  If `degenerate`, a (possibly discontinuous) time
series will be returned with two points exactly at each segment junction.
"""
function pointseries(ss::SegmentSeries; check_continuity::Bool=false,
                     δ::AbstractFloat=DISCONTINUITY_δ,
                     degenerate::Bool=false)
    continuous!(ss, check=check_continuity)
    if ss.cont
        return _pointseries_continuous(ss)
    elseif degenerate
        return _pointseries_discontinuous(ss)
    end
    _pointseries_discontinuous_hack(ss, δ)
end
export pointseries


"""
    slope(s)

Returns the slope of a linear segment, or a series of slopes of a `SegmentSeries`.
"""
slope(s::LinearSegment) = (s.x1 - s.x0)/(s.t1 - s.t0)

function slope{S<:LinearSegment}(segseries::SegmentSeries{S})
    [slope(s) for s ∈ segseries]
end

"""
    intercept(s)

Returns the vertical-axis intercept of a linear segment, or a series of intercepts of a
`SegmentSeries`.
"""
intercept(s::LinearSegment) = (s.t1*s.x0 - s.t0*s.x1)/(s.t1 - s.t0)

function intercept{S<:LinearSegment}(segseries::SegmentSeries{S})
    [intercept(s) for s ∈ segseries]
end

"""
    loss([loss_func, ]segment, t, x)
    loss([loss_func, ]f, t, x)

Computes the error of the segment relative to the points specified by `t,x`, according
to the loss metric `loss_func`.  If no `loss_func` is given, this defaults to `L₂`.
Alternatively, this can compute the error of an arbitrary function `f` relative to the
points `t, x`.
"""
function loss{T<:Number,U<:Number}(loss_func::Function, f::Function,
                                   t::Vector{T}, x::Vector{U})
    xPrime = f.(t)
    loss_func(xPrime - x)
end
function loss{T<:Number,U<:Number}(loss_func::Function, 
                                   s::Union{LinearSegment, SegmentSeries},
                                   t::Vector{T}, x::Vector{U})
    loss(loss_func, getfunction(s), t, x)
end
function loss{T<:Number,U<:Number}(f::Function, t::Vector{T}, x::Vector{U})
    loss(L₂, f, t, x)
end
function loss{T<:Number,U<:Number}(s::Union{LinearSegment, SegmentSeries}, 
                                   t::Vector{T}, x::Vector{U})
    loss(L₂, s, t, x)
end

export slope, intercept, loss


"""
    LinearSegmentInterpolation(t, x)

Constructs a linear segment by interpolating between the endpoints of the series specified
by `t, x`.  This method is guaranteed to produce a continuous series of applied to the 
entirety of a time-series.
"""
function LinearSegmentInterpolation{T<:Number,U<:Number}(t::Vector{T}, x::Vector{U}
                                                        )::LinearSegment
    LinearSegment(t[1], x[1], t[end], x[end])
end
export LinearSegmentInterpolation

"""
    LinearSegmentRegression(t, x)

Constructs a linear segment by performing a least-squares regression on the series specified
by `t, x`.  This method does not in general produce continuous series.
"""
function LinearSegmentRegression{T<:Number,U<:Number}(t::Vector{T}, x::Vector{U}
                                                     )::LinearSegment
    a, b = linreg(t, x)
    f(ξ::Number) = b*ξ + a
    LinearSegment(t[1], f(t[1]), t[end], f(t[end]))
end
export LinearSegmentRegression


"""
    LinearSegment(t, x[, segtype=:interpolation])

Produces a linear segment from `t, x` using the method specified by `segtype`.  See the
documenation for specific `LinearSegment` construction methods.
"""
function LinearSegment{T<:Number,U<:Number}(t::Vector{T}, x::Vector{U}, 
                                            segtype::Symbol=:interpolation)
    if segtype ∈ [:interpolation, :Interpolation]
        constructor = LinearSegmentInterpolation
    elseif segtype ∈ [:regression, :Regression]
        constructor = LinearSegmentRegression
    else
        throw(ArgumentError("Segment type must be either `:interpolation` or `:regression`."))
    end
    constructor(t, x)
end


"""
    window(t, x, range)

Gives only the subset within `range` of points in `t, x`.  i.e. this just returns the 
ordered pair `t[range], x[range]`.
"""
function window(t::Vector, x::Vector, range::UnitRange)
    t[range], x[range]
end


# TODO assumes already sorted, ensure segments can't get inserted out of order
"""
    getfunction(s)
    getfunction(ss)
    getfunction(ts)

Returns the function of the segment `s` or `SegmentSeries` `ss`.

Returns the function of the `SegmentSeries` `ss`.  Note that if the `SegmentSeries` is 
discontinuous at `t₀` the function is defined using the segment found at `t = t₀ + ɛ` where
`ɛ > 0` at `t₀`.

This can also be called on a `TimeArray` object.  In this case, it returns a function 
corresponding to linear interpolation between points in the time series.  This makes the
most sense to use when the sampling frequency is ≲ the time series lattice spacing.
"""
getfunction(s::LinearSegment) = ξ -> slope(s)*ξ + intercept(s)
function getfunction{S<:LinearSegment}(ss::SegmentSeries{S})
    lpoints = [s.t0 for s ∈ ss] # assumes no overlapping segments
    function ofunc(t::Number)
        idx = searchsortedlast(lpoints, t) # guaranteed to be this segment
        slope(ss[idx])*t + intercept(ss[idx]) 
    end
end

function getfunction{T<:Dates.Period}(ts::TimeArray, ::Type{T})
    ss = SegmentSeries(ts, T)
    getfunction(ss)
end

export getfunction



