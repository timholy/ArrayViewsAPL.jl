module ArrayViewsAPL

import Base: copy, eltype, getindex, length, ndims, setindex!, similar, size

export View

# Tasks:
#    creating a View from an AbstractArray---done
#    creating a View from a View (should "pop" the old view and create a more compact one)
#    scalar-indexing a View{T,N} using N indexes---done
#    scalar-indexing a View{T,N} with < N indexes aka linear indexing (ugh)---done
#    utility functions like length, size---done
#    copy, similar---done
# Decisions (which will turn into tasks, once decided):
#    In writing getindex generally, do AbstractVector inputs make a copy or a view?
#      (One question is whether it's better to reorganize the data for
#       good cache behavior---might as well get it done at the beginning---or is it better to
#       minimize memory usage/construction time? Maybe we need both options.)
#    If we want APL, must generalize to more than 1d indexes. Does this always create a copy? If so,
#       we only have to generalize getindex, the View type does not need generalization.
# Related issues that need to be tackled:
#    boundschecking (approach: introduce Expr(:withmeta, expr, :boundscheck) expressions, created like this:
#                        @boundscheck 1 <= i <= size(A,1) || throw(BoundsError())
#                    and teach codegen to look for such expressions, skipping them if inside @inbounds.
#                    See https://github.com/JuliaLang/julia/pull/3796#issuecomment-21433164)

immutable View{T,N,P<:AbstractArray,I<:(RangeIndex...)} <: AbstractArray{T,N} # <: ArrayView{T,N,0}
    parent::P
    indexes::I
    dims::NTuple{N,Int}
end

# Simple utilities
eltype{T,N,P,I}(V::View{T,N,P,I}) = T
eltype{T,N,P,I}(::Type{View{T,N,P,I}}) = T
ndims{T,N,P,I}(V::View{T,N,P,I}) = N
ndims{T,N,P,I}(::Type{View{T,N,P,I}}) = N
size(V::View) = V.dims
size(V::View, d::Integer) = d <= ndims(V) ? (@inbounds ret = V.dims[d]; ret) : 1
length(V::View) = prod(V.dims)
similar(V::View, T, dim::Dims) = similar(V.parent, T, dims)

# Constructor
stagedfunction View(A::AbstractArray, I::RangeIndex...)
    N = 0
    sizeexprs = Any[]
    for k = 1:length(I)
        i = I[k]
        if !(i <: Real)
            N += 1
            push!(sizeexprs, :(length(I[$k])))
        end
    end
    dims = :(tuple($(sizeexprs...)))
    T = eltype(A)
    :(ArrayViewsAPL.View{$T,$N,$A,$I}(A, I, $dims))
end


# Scalar indexing
stagedfunction getindex(V::View, i1::Real)
    exhead, ex = index_generate(V, :V, [:i1])
    quote
        $exhead
        $ex
    end
end
stagedfunction getindex(V::View, i1::Real, i2::Real)
    exhead, ex = index_generate(V, :V, [:i1, :i2])
    quote
        $exhead
        $ex
    end
end
stagedfunction getindex(V::View, i1::Real, i2::Real, i3::Real)
    exhead, ex = index_generate(V, :V, [:i1, :i2, :i3])
    quote
        $exhead
        $ex
    end
end
stagedfunction getindex(V::View, i1::Real, i2::Real, i3::Real, i4::Real)
    exhead, ex = index_generate(V, :V, [:i1, :i2, :i3, :i4])
    quote
        $exhead
        $ex
    end
end
stagedfunction getindex(V::View, I::Real...)
    Isyms = [:(I[$d]) for d = 1:length(I)]
    exhead, ex = index_generate(V, :V, Isyms)
    quote
        $exhead
        $ex
    end
end
# V[] notation (extracts the first element)
stagedfunction getindex(V::View)
    Isyms = ones(Int, ndims(V))
    exhead, ex = index_generate(V, :V, Isyms)
    quote
        $exhead
        $ex
    end
end

stagedfunction setindex!(V::View, v, i1::Real)
    exhead, ex = index_generate(V, :V, [:i1])
    quote
        $exhead
        $ex = v
    end
end
stagedfunction setindex!(V::View, v, i1::Real, i2::Real)
    exhead, ex = index_generate(V, :V, [:i1, :i2])
    quote
        $exhead
        $ex = v
    end
end
stagedfunction setindex!(V::View, v, i1::Real, i2::Real, i3::Real)
    exhead, ex = index_generate(V, :V, [:i1, :i2, :i3])
    quote
        $exhead
        $ex = v
    end
end
stagedfunction setindex!(V::View, v, i1::Real, i2::Real, i3::Real, i4::Real)
    exhead, ex = index_generate(V, :V, [:i1, :i2, :i3, :i4])
    quote
        $exhead
        $ex = v
    end
end
stagedfunction setindex!(V::View, v, I::Real...)
    Isyms = [:(I[$d]) for d = 1:length(I)]
    exhead, ex = index_generate(V, :V, Isyms)
    quote
        $exhead
        $ex = v
    end
end

function index_generate(V, Vsym, Isyms)
    T, N, P, I = V.parameters
    exhead = :nothing
    if length(Isyms) < N
        # Linear indexing in the last index
        n = N - length(Isyms)
        m = length(Isyms)
        strides = [gensym() for i = 1:n]
        indexes = [gensym() for i = 1:n+1]
        resid = gensym()
        linblock = Array(Expr, 2n+2)
        linblock[1] = :($(strides[1]) = size($Vsym, $m))
        for k = 2:n
            m += 1
            linblock[k] = :($(strides[k]) = $(strides[k-1]) * size($Vsym, $m))
        end
        k = n+1
        linblock[k] = :($resid = $(Isyms[end])-1)
        for i = n:-1:1
            k += 1
            linblock[k] = quote
                $(indexes[i+1]), $resid = divrem($resid, $(strides[i]))
                $(indexes[i+1]) += 1
            end
        end
        linblock[end] = :($(indexes[1]) = $resid+1)
        exhead = Expr(:block, linblock...)
        pop!(Isyms)
        append!(Isyms, indexes)
    elseif length(Isyms) != N
        error("Wrong number of indexes supplied")
    end
    NP = length(I)
    indexexprs = Array(Expr, NP)
    j = 1
    for i = 1:NP
        if I[i] <: Real
            indexexprs[i] = :($Vsym.indexes[$i])
        else
            indexexprs[i] = :($Vsym.indexes[$i][$(Isyms[j])])  # TODO: make Range bounds-checking respect @inbounds
            j += 1
        end
    end
    exhead, :($Vsym.parent[$(indexexprs...)])
end

# More utility functions
stagedfunction copy(V::View)
    T, N = eltype(V), ndims(V)
    quote
        A = Array($T, V.dims)
        k = 1
        Base.Cartesian.@nloops $N i A begin
            @inbounds A[k] = Base.Cartesian.@nref($N, V, i)
            k += 1
        end
        A
    end
end

end