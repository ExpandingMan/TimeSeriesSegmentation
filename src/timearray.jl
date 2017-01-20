
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
function convertaxis{T<:Dates.Period,U<:Number,V<:Number}(::Type{T}, t::Vector{U}, 
                                                          x::Vector{V},
                                                          t0::Dates.TimeType)
    # TODO this is really bad for cases where we deal with large numbers of years
    t = [t0 + Dates.Millisecond(convert_ms_inv(T, τ)) for τ ∈ t]
    TimeArray(t, x)
end


