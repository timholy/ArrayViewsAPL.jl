function as_sub(x::AbstractMatrix)
    y = similar(x, eltype(x), tuple(([size(x)...]*2)...))
    y = subview(y, 2:2:size(y,1), 2:2:size(y,2))
    for j=1:size(x,2)
        for i=1:size(x,1)
            y[i,j] = x[i,j]
        end
    end
    y
end

as_sub(eye(2))
