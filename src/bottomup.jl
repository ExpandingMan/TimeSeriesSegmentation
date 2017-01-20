
#============
    TODO

    This algorithm is a horrible mess and very inefficient, but it works.
    I think the best way to clean it up is to create some sort of ``segment" type.
    However, ideally that should wrap a time-series object, and I'm waiting for support
    of time-series with floating point axes to be merged into TimeSeries master.

    So, I really should revisit this and rewrite it once that is done.
======#


function bottomup{T<:Number, U<:Number}(t::Vector{T}, x::Vector{U},
                                        max_error::AbstractFloat,
                                        segment_func::Function,
                                        error_func::Function;
                                        segment_join::Function=join_discontinuous!)
    @assert length(t) == length(x) "Invalid time series axis."
    all_segs = [segment_func(t[i:(i+1)], x[i:(i+1)]) for i ∈ 1:length(t)-1]
    tsegs = Dict(i=>all_segs[i][1] for i ∈ 1:length(all_segs))
    xsegs = Dict(i=>all_segs[i][2] for i ∈ 1:length(all_segs))
    lconnect = Dict(i=>(i-1) for i ∈ 2:length(t))
    rconnect = Dict(i=>(i+1) for i ∈ 1:length(t)-1)

    losses = Dict();  sizehint!(losses, length(t)-2)
    for i ∈ 2:(length(t)-1)  # loop for initializing losses
        tnow = t[(i-1): (i+1)]
        xnow = x[(i-1): (i+1)]
        tseg, xseg = segment_func(tnow, xnow)
        losses[i] = error_func(tseg, xseg, tnow, xnow)
    end
    losses_rev = Dict(v=>k for (k, v) ∈ losses)

    min_loss = minimum(collect(values(losses)))

    # second condition checks if we are down to only one segment
    while min_loss < max_error && length(values(tsegs)) > 1
        i = losses_rev[min_loss]
        idx_left  = lconnect[i]
        idx_right = rconnect[i]
        tnow = t[idx_left:idx_right]
        xnow = x[idx_left:idx_right]
        tseg, xseg = segment_func(tnow, xnow)
        delete!(tsegs, idx_left); delete!(xsegs, idx_left)
        delete!(tsegs, i); delete!(xsegs, i)
        delete!(losses, i)
        delete!(losses_rev, min_loss)
        delete!(lconnect, i)
        delete!(rconnect, i)
        lconnect[idx_right] = idx_left
        rconnect[idx_left]  = idx_right
        # computing new losses, unless reached end
        if idx_left > 1
            tnow_left = t[lconnect[idx_left]: idx_right]
            xnow_left = x[lconnect[idx_left]: idx_right]
            tseg_left, xseg_left = segment_func(tnow_left, xnow_left)
            losses[idx_left] = error_func(tseg_left, xseg_left, tnow_left, xnow_left)
        end
        if idx_right < length(t)
            tnow_right = t[idx_left:rconnect[idx_right]]
            xnow_right = x[idx_left:rconnect[idx_right]]
            tseg_right, xseg_right = segment_func(tnow_right, xnow_right)
            losses[idx_right] = error_func(tseg_right, xseg_right, tnow_right, xnow_right)
        end
        # TODO fix this
        losses_rev = Dict(v=>k for (k, v) ∈ losses)
        if length(losses) > 0
            min_loss = minimum(collect(values(losses)))
        else
            min_loss = Inf  # this will cause the loop to exit
        end
        # assigning new segments
        tsegs[idx_left] = tseg
        xsegs[idx_left] = xseg
    end

    tout = reduce(segment_join, [tsegs[i] for i ∈ sort(collect(keys(tsegs)))])
    xout = reduce(segment_join, [xsegs[i] for i ∈ sort(collect(keys(xsegs)))])

    tout, xout
end


function bottomup_interpolation{T<:Number, U<:Number}(t::Vector{T}, x::Vector{U},
                                                      max_error::AbstractFloat,
                                                      err_func::Function=L₂;
                                                      segment_join::Function=join_continuous!)
    E(t1, x1, t2, x2) = error_linear(t1, x1, t2, x2, err_func)
    bottomup(t, x, max_error, segment_interpolation, E, segment_join=segment_join)
end


function bottomup_regression{T<:Number, U<:Number}(t::Vector{T}, x::Vector{U},
                                                   max_error::AbstractFloat,
                                                   err_func::Function=L₂;
                                                   segment_join::Function=join_discontinuous!)
    E(t1, x1, t2, x2) = error_linear(t1, x1, t2, x2, err_func)
    bottomup(t, x, max_error, segment_regression, E, segment_join=segment_join)
end




