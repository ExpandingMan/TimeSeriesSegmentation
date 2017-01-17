


function topdown{T<:Number, U<:Number}(t::Vector{T}, x::Vector{U},
                                       max_error::AbstractFloat,
                                       segment_func::Function,
                                       error_func::Function;
                                       segment_join::Function=join_discontinuous!,
                                       recursion_depth::Integer=0,
                                       max_recursion_depth::Integer=5) # TODO debugging
    least_loss = Inf
    split_node = -1
    loss_left = Inf
    loss_right = Inf
    tseg_left_best = Vector{T}(0)
    xseg_left_best = Vector{U}(0)
    tseg_right_best = Vector{T}(0)
    xseg_right_best = Vector{U}(0)
    for i ∈ 2:(length(t)-1)
        tleft = t[1:i];  tright = t[i:end]
        xleft = x[1:i];  xright = x[i:end]
        tseg_left, xseg_left   = segment_func(tleft, xleft)
        tseg_right, xseg_right = segment_func(tright, xright)
        loss_left  = error_func(tseg_left, xseg_left, tleft, xleft)
        loss_right = error_func(tseg_right, xseg_right, tright, xright)
        loss = loss_left + loss_right  # for now we just add the losses
        if loss < least_loss
            least_loss = loss
            split_node = i
            tseg_left_best, xseg_left_best = tseg_left, xseg_left
            tseg_right_best, xseg_right_best = tseg_right, xseg_right
        end
    end

    # TODO somehow segment_join is getting passed an empty array somewhere

    recursion_depth += 1

    if loss_left > max_error && recursion_depth ≤ max_recursion_depth
        tseg_left_best, xseg_left_best = topdown(t[1:split_node], x[1:split_node], max_error,
                                segment_func, error_func, segment_join=segment_join,
                                recursion_depth=recursion_depth,
                                max_recursion_depth=max_recursion_depth)
    end

    if loss_right > max_error && recursion_depth ≤ max_recursion_depth
        tseg_right_best, xseg_right_best = topdown(t[split_node:end], 
                                    x[split_node:end], max_error,
                                    segment_func, error_func, segment_join=segment_join,
                                    recursion_depth=recursion_depth,
                                    max_recursion_depth=max_recursion_depth)
    end

    segment_join(tseg_left_best, tseg_right_best)
    segment_join(xseg_left_best, xseg_right_best)

    tseg_left_best, xseg_left_best
end


function topdown_interpolation{T<:Number, U<:Number}(t::Vector{T}, x::Vector{U},
                                                     max_error::AbstractFloat,
                                                     err_func::Function=L₂;
                                                     segment_join::Function=join_continuous!)
    E(t1, x1, t2, x2) = error_linear(t1, x1, t2, x2, err_func)
    topdown(t, x, max_error, segment_interpolation, E, segment_join=segment_join)
end


function topdown_regression{T<:Number, U<:Number}(t::Vector{T}, x::Vector{U},
                                                  max_error::AbstractFloat,
                                                  err_func::Function=L₂;
                                                  segment_join::Function=join_discontinuous!)
    E(t1, x1, t2, x2) = error_linear(t1, x1, t2, x2, err_func)
    topdown(t, x, max_error, segment_regression, E, segment_join=segment_join)
end

