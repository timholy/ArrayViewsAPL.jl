module ArrayViewsAPL

import Base: copy, eltype, getindex, length, ndims, setindex!, similar, size

export
    # types
    View,
    # functions
    sliceview,
    subview

# Tasks:
#    creating a View from an AbstractArray---done
#    creating a View from a View---done
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

typealias ViewIndex Union(Int, UnitRange{Int}, StepRange{Int,Int}, Vector{Int})
typealias NonSliceIndex Union(UnitRange{Int}, StepRange{Int,Int}, Vector{Int})

# Since there are no multidimensional range objects, we only permit 1d indexes
immutable View{T,N,P<:AbstractArray,I<:(ViewIndex...)} <: AbstractArray{T,N}
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

## View creation
# APL-style.
stagedfunction sliceview(A::AbstractArray, I::ViewIndex...)
    length(I) == ndims(A) || error("$(length(I)) indexes does not match $A")
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

# Conventional style (drop trailing singleton dimensions, keep any other singletons)
stagedfunction subview(A::AbstractArray, I::ViewIndex...)
    length(I) == ndims(A) || error("$(length(I)) indexes does not match $A")
    sizeexprs = Any[]
    Itypes = Any[]
    Iexprs = Any[]
    N = length(I)
    while N > 0 && I[N] <: Real
        N -= 1
    end
    for k = 1:length(I)
        if k <= N
            push!(sizeexprs, :(length(I[$k])))
        end
        if k <= N && I[k] <: Real
            push!(Itypes, UnitRange{Int})
            push!(Iexprs, :(int(I[$k]):int(I[$k])))
        else
            push!(Itypes, I[k])
            push!(Iexprs, :(I[$k]))
        end
    end
    dims = :(tuple($(sizeexprs...)))
    Iext = :(tuple($(Iexprs...)))
    T = eltype(A)
    It = tuple(Itypes...)
    :(ArrayViewsAPL.View{$T,$N,$A,$It}(A, $Iext, $dims))
end

# Constructing from another View
# This "pops" the old View and creates a more compact one
stagedfunction sliceview(V::View, I::ViewIndex...)
    T, NV, PV, IV = V.parameters
    length(I) == NV || error("$(length(I)) indexes does not match $V")
    N = 0
    sizeexprs = Any[]
    indexexprs = Any[]
    Itypes = Any[]
    k = 0
    for j = 1:length(IV)
        if IV[j] <: Real
            push!(indexexprs, :(V.indexes[$j]))
            push!(Itypes, IV[j])
        else
            k += 1
            if !(I[k] <: Real)
                N += 1
                push!(sizeexprs, :(length(I[$k])))
            end
            push!(indexexprs, :(V.indexes[$j][I[$k]]))
            push!(Itypes, rangetype(IV[j], I[k]))
        end
    end
    Inew = :(tuple($(indexexprs...)))
    dims = :(tuple($(sizeexprs...)))
    It = tuple(Itypes...)
    :(ArrayViewsAPL.View{$T,$N,$PV,$It}(V.parent, $Inew, $dims))
end

stagedfunction subview(V::View, I::ViewIndex...)
    T, NV, PV, IV = V.parameters
    length(I) == NV || error("$(length(I)) indexes does not match $V")
    N = length(I)
    while N > 0 && I[N] <: Real
        N -= 1
    end
    sizeexprs = Any[]
    indexexprs = Any[]
    Itypes = Any[]
    k = 0
    for j = 1:length(IV)
        if IV[j] <: Real
            push!(indexexprs, :(V.indexes[$j]))
            push!(Itypes, IV[j])
        else
            k += 1
            if k <= N
                push!(sizeexprs, :(length(I[$k])))
            end
            if k <= N && I[k] <: Real
                push!(indexexprs, :(V.indexes[$j][int(I[$k]):int(I[$k])]))
                push!(Itypes, rangetype(IV[j], UnitRange{Int}))
            else
                push!(indexexprs, :(V.indexes[$j][I[$k]]))
                push!(Itypes, rangetype(IV[j], I[k]))
            end
        end
    end
    Inew = :(tuple($(indexexprs...)))
    dims = :(tuple($(sizeexprs...)))
    It = tuple(Itypes...)
    :(ArrayViewsAPL.View{$T,$N,$PV,$It}(V.parent, $Inew, $dims))
end

function rangetype(T1, T2)
    rt = Base.return_types(getindex, (T1, T2))
    length(rt) == 1 || error("Can't infer return type")
    rt[1]
end

# Scalar indexing
# Low dimensions: avoid splatting
vars = Expr[]
typedvars = Expr[]
for i = 1:4
    sym = symbol(string("i",i))
    push!(vars, Expr(:quote, sym))
    push!(typedvars, :($sym::Real))
    @eval begin
        stagedfunction getindex(V::View, $(typedvars...))
            exhead, ex = index_generate(V, :V, [$(vars...)])
            quote
                $exhead
                $ex
            end
        end
        stagedfunction setindex!(V::View, v, $(typedvars...))
            exhead, ex = index_generate(V, :V, [$(vars...)])
            quote
                $exhead
                $ex = v
            end
        end
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
# Splatting variants
stagedfunction getindex(V::View, I::Real...)
    Isyms = [:(I[$d]) for d = 1:length(I)]
    exhead, ex = index_generate(V, :V, Isyms)
    quote
        $exhead
        $ex
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

function index_generate(Nd, Itypes, Vsym, Isyms)
    if isempty(Isyms)
        Isyms = Any[1]  # this handles the syntax getindex(V)
    end
    exhead = :nothing
    if length(Isyms) < Nd
        # Linear indexing in the last index
        n = Nd - length(Isyms)
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
    end
    NP = length(Itypes)
    indexexprs = Array(Any, NP)
    j = 0
    for i = 1:NP
        if Itypes[i] <: Real
            indexexprs[i] = :($Vsym.indexes[$i])
        else
            j += 1
            indexexprs[i] = :(unsafe_getindex($Vsym.indexes[$i], $(Isyms[j])))  # TODO: make Range bounds-checking respect @inbounds
        end
    end
    # Append any extra indexes. Must be trailing 1s or it will cause a BoundsError.
    for k = j+1:length(Isyms)
        push!(indexexprs, :($(Isyms[k])))
    end
    exhead, :($Vsym.parent[$(indexexprs...)])
end

## Implementations of getindex for AbstractArrays and Views

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