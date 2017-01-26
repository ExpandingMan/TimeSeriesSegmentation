
#============================================================================================
    These are some simple tools for doing fourier analysis on time series and segment series.

    TODO:
    This package really isn't the place for this.  Move it to somewhere more appropriate.

    TODO:
    Allow for arbitrary sampling frequencies

    TODO: using segment series as an intermediate state for the time series is bad

============================================================================================#


function fft(ss::SegmentSeries, N::Integer)
    f = getfunction(ss)
    trange = ss[end].t1 - ss[1].t0
    tnew = ss[1].t0 + 0.0:(trange/N):trange
    xnew = f.(tnew)
    fft(xnew)
end


function fft(ss::SegmentSeries)
    N = convert(Int64, ss[end].t1 - ss[1].t0)
    fft(ss, N)
end


function fft{T<:Dates.Period,U,NN,D<:Dates.TimeType,A}(ts::TimeArray{U,NN,D,A}, 
                                                       ::Type{T}, N::Integer;
                                                       t0::D=ts.timestamp[1])
    ss = SegmentSeries(ts, T, t0)
    fft(ss, N)
end


function fft{T<:Dates.Period,U,N,D<:Dates.TimeType,A}(ts::TimeArray{U,N,D,A},
                                                      ::Type{T}; t0::D=ts.timestamp[1])
    ss = SegmentSeries(ts, T, t0)
    fft(ss)
end

                                      
export fft

