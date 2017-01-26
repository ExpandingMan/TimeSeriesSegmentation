

# definition of year as 365 days is consistent with Dates package

convert_ms(::Type{Dates.Millisecond}, t::Number) = t
convert_ms(::Type{Dates.Second}, t::Number) = t/1000
convert_ms(::Type{Dates.Minute}, t::Number) = t/(1000*60)
convert_ms(::Type{Dates.Hour}, t::Number) = t/(1000*60*60)
convert_ms(::Type{Dates.Day}, t::Number) = t/(1000*60*60*24)
convert_ms(::Type{Dates.Year}, t::Number) = t/(1000*60*60*24*365)

convert_ms_inv(::Type{Dates.Millisecond}, t::Number) = t
convert_ms_inv(::Type{Dates.Second}, t::Number) = t*1000
convert_ms_inv(::Type{Dates.Minute}, t::Number) = t*1000*60
convert_ms_inv(::Type{Dates.Hour}, t::Number) = t*1000*60*60
convert_ms_inv(::Type{Dates.Day}, t::Number) = t*1000*60*60*24
convert_ms_inv(::Type{Dates.Year}, t::Number) = t*1000*60*60*24*365

convert_day(::Type{Dates.Millisecond}, t::Number) = t*24*60*60*1000
convert_day(::Type{Dates.Second}, t::Number) = t*24*60*60
convert_day(::Type{Dates.Minute}, t::Number) = t*24*60
convert_day(::Type{Dates.Hour}, t::Number) = t*24
convert_day(::Type{Dates.Day}, t::Number) = t
convert_day(::Type{Dates.Year}, t::Number) = t/365


# this is definitely not the ideal way of doing this, but options are limited
function float2datetime{T<:Dates.Period}(x::AbstractFloat, units::T, t0::DateTime)
    n = trunc(Int64, x)
    remainder = x - n
    c₁ = n*units
    c₂ = Int64(units)*Dates.Millisecond(trunc(Int64, convert_ms_inv(T, remainder)))
    t0 + c₁ + c₂ 
end


"""
    convertaxis([T, ]ts, t0=ts.timestamp[1])

Returns a pair of vectors, the first of which is the time locations of points in the 
`TimeArray` `ts` with units `T` with time `t0` being evaluated as `0.0`.  The second is
simply the values of the `TimeArray`.
"""
function convertaxis{T<:Dates.Period, U,N,D<:DateTime,A}(::Type{T}, ta::TimeArray{U,N,D,A}, 
                                                         t0::D=ta.timestamp[1])
    t = [convert_ms(T, convert(Float64, τ - t0)) for τ ∈ ta.timestamp]
    t, ta.values
end
function convertaxis{T<:Dates.Period, U,N,D<:Date,A}(::Type{T}, ta::TimeArray{U,N,D,A},
                                                     t0::D=ta.timestamp[1])
    t = [convert_day(T, convert(Float64, τ - t0)) for τ ∈ ta.timestamp]
    t, ta.values
end
function convertaxis{U,N,D<:DateTime,A}(ta::TimeArray{U,N,D,A}, t0::AbstractFloat=0.0)
    t = [datetime2unix(τ) - t0 for τ ∈ ta.timestamp]
    t, ta.values
end
function convertaxis{U,N,D<:Date,A}(ta::TimeArray{U,N,D,A}, t0::AbstractFloat=0.0)
    t = [datetime2unix(DateTime(τ)) - t0 for τ ∈ ta.timestamp]
    t, ta.values
end

# these are the inverse conversions
function TimeArray{T<:Dates.Period,U<:Number,V<:Number}(::Type{T}, t::Vector{U}, 
                                                        x::Vector{V},
                                                        t0::Dates.TimeType)
    t = [float2datetime(τ, one(T), t0) for τ ∈ t]
    TimeArray(t, x)
end

export convertaxis


# conversions to and from SegmentSeries


function SegmentSeries{U,N,D,A,T<:Dates.Period}(ta::TimeArray{U,N,D,A}, ::Type{T}, 
                                                t0::D=ta.timestamp[1])
    t, x = convertaxis(T, ta, t0)
    SegmentSeries(t, x, LinearSegmentInterpolation, units=T, t0=DateTime(t0))
end


function TimeArray(ss::SegmentSeries; check_continuity::Bool=false,
                   δ::AbstractFloat=DISCONTINUITY_δ)
    # this now works even for discontinuous
    t, x = pointseries(ss, check_continuity=check_continuity, degenerate=false)
    TimeArray(ss.units, t, x, ss.zero)
end


convert(::Type{TimeArray}, ss::SegmentSeries) = TimeArray(ss, check_continuity=true) 
export convert

