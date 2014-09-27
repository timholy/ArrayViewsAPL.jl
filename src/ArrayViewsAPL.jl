module ArrayViewsAPL

using Base.Cartesian

import Base: convert, copy, eltype, getindex, length, ndims, parent, parentdims,
    parentindexes, pointer, setindex!, similar, size, stride, strides

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
#    stride, strides---done
#    pointer and convert(Ptr{T}, V)---done
#    boolean indexing? This seems problematic, we probably want copies in that case.
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

typealias NonSliceIndex Union(UnitRange{Int}, StepRange{Int,Int}, Vector{Int})
typealias ViewIndex Union(Int, NonSliceIndex)

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
similar(V::View, T, dims::Dims) = similar(V.parent, T, dims)

parent(V::View) = V.parent
parentindexes(V::View) = V.indexes

## View creation
# APL-style.
stagedfunction sliceview(A::AbstractArray, I::ViewIndex...)
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
        if k < N && I[k] <: Real
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
            if k < length(I) || j == length(IV)
                if !(I[k] <: Real)
                    N += 1
                    push!(sizeexprs, :(length(I[$k])))
                end
                push!(indexexprs, :(V.indexes[$j][I[$k]]))
                push!(Itypes, rangetype(IV[j], I[k]))
            else
                # We have a linear index that spans more than one dimension of the parent
                N += 1
                push!(sizeexprs, :(length(I[$k])))
                push!(indexexprs, :(ArrayViewsAPL.merge_indexes(V.indexes[$j:end], size(V.parent)[$j:end], I[$k])))
                push!(Itypes, Array{Int, 1})
                break
            end
        end
    end
    for i = k+1:length(I)
        if !(I[i] <: Real)
            N += 1
            push!(sizeexprs, :(length(I[$i])))
        end
        push!(indexexprs, :(I[$i]))
        push!(Itypes, I[i])
    end
    Inew = :(tuple($(indexexprs...)))
    dims = :(tuple($(sizeexprs...)))
    It = tuple(Itypes...)
    :(ArrayViewsAPL.View{$T,$N,$PV,$It}(V.parent, $Inew, $dims))
end

stagedfunction subview(V::View, I::ViewIndex...)
    T, NV, PV, IV = V.parameters
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
            if k < N && I[k] <: Real
                # convert scalar to a range
                push!(indexexprs, :(V.indexes[$j][int(I[$k]):int(I[$k])]))
                push!(Itypes, rangetype(IV[j], UnitRange{Int}))
            elseif k < length(I) || j == length(IV)
                # simple indexing
                push!(indexexprs, :(V.indexes[$j][I[$k]]))
                push!(Itypes, rangetype(IV[j], I[k]))
            else
                # We have a linear index that spans more than one dimension of the parent
                push!(indexexprs, :(ArrayViewsAPL.merge_indexes(V.indexes[$j:end], size(V.parent)[$j:end], I[$k])))
                push!(Itypes, Array{Int, 1})
                break
            end
        end
    end
    for i = k+1:length(I)
        if i <= N
            push!(sizeexprs, :(length(I[$i])))
        end
        push!(indexexprs, :(I[$i]))
        push!(Itypes, I[i])
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

subview(A::AbstractArray, I::Union(ViewIndex, Colon)...) = subview(A, ntuple(length(I), i-> isa(I[i], Colon) ? (1:size(A,i)) : I[i])...)
sliceview(A::AbstractArray, I::Union(ViewIndex, Colon)...) = sliceview(A, ntuple(length(I), i-> isa(I[i], Colon) ? (1:size(A,i)) : I[i])...)


## Strides
stagedfunction strides(V::View)
    T,N,P,I = V.parameters
    all(map(x->x<:RangeIndex, I)) || error("strides valid only for RangeIndex indexing")
    strideexprs = Array(Any, N+1)
    strideexprs[1] = 1
    i = 1
    Vdim = 1
    for i = 1:length(I)
        if !(I[i]==Int)
            strideexprs[Vdim+1] = copy(strideexprs[Vdim])
            strideexprs[Vdim] = :(step(V.indexes[$i])*$(strideexprs[Vdim]))
            Vdim += 1
        end
        strideexprs[Vdim] = :(size(V.parent, $i) * $(strideexprs[Vdim]))
    end
    :(tuple($(strideexprs[1:N]...)))
end

stride(V::View, d::Integer) = d <= ndims(V) ? strides(V)[d] : strides(V)[end] * size(V)[end]

## Pointer conversion (for ccall)
function first_index(V::View)
    f = 1
    s = 1
    for i = 1:length(V.indexes)
        f += (first(V.indexes[i])-1)*s
        s *= size(V.parent, i)
    end
    f
end

convert{T,N,P<:Array,I<:(RangeIndex...)}(::Type{Ptr{T}}, V::View{T,N,P,I}) =
    pointer(V.parent) + (first_index(V)-1)*sizeof(T)

pointer(V::View, i::Int) = pointer(V, ind2sub(size(V), i))

function pointer{T,N,P<:Array,I<:(RangeIndex...)}(V::View{T,N,P,I}, is::(Int...))
    index = first_index(V)
    strds = strides(V)
    for d = 1:length(is)
        index += (is[d]-1)*strds[d]
    end
    return pointer(V.parent, index)
end

## Convert
convert{T,S,N}(::Type{Array{T,N}}, V::View{S,N}) = copy!(Array(T, size(V)), V)

## Scalar indexing
# Low dimensions: avoid splatting
vars = Expr[]
varsInt = Expr[]
varsReal = Expr[]
vars_toindex = Expr[]
for i = 1:4
    sym = symbol(string("i",i))
    push!(vars, Expr(:quote, sym))
    push!(varsInt, :($sym::Int))
    push!(varsReal, :($sym::Real))
    push!(vars_toindex, :(Base.to_index($sym)))
    @eval begin
        stagedfunction getindex(V::View, $(varsInt...))
            T, N, P, IV = V.parameters
            exhead, ex = index_generate(ndims(P), IV, :V, [$(vars...)])
            quote
                $exhead
                $ex
            end
        end
        stagedfunction setindex!(V::View, v, $(varsInt...))
            T, N, P, IV = V.parameters
            exhead, ex = index_generate(ndims(P), IV, :V, [$(vars...)])
            quote
                $exhead
                $ex = v
            end
        end
        getindex(V::View, $(varsReal...)) = getindex(V::View, $(vars_toindex...))
        setindex!(V::View, v, $(varsReal...)) = setindex!(V::View, v, $(vars_toindex...))
    end
end
# V[] notation (extracts the first element)
stagedfunction getindex(V::View)
    T, N, P, IV = V.parameters
    Isyms = ones(Int, N)
    exhead, ex = index_generate(ndims(P), IV, :V, Isyms)
    quote
        $exhead
        $ex
    end
end
# Splatting variants
stagedfunction getindex(V::View, I::Int...)
    T, N, P, IV = V.parameters
    Isyms = [:(I[$d]) for d = 1:length(I)]
    exhead, ex = index_generate(ndims(P), IV, :V, Isyms)
    quote
        $exhead
        $ex
    end
end
stagedfunction setindex!(V::View, v, I::Int...)
    T, N, P, IV = V.parameters
    Isyms = [:(I[$d]) for d = 1:length(I)]
    exhead, ex = index_generate(ndims(P), IV, :V, Isyms)
    quote
        $exhead
        $ex = v
    end
end
getindex(V::View, I::Real...) = getindex(V, to_index(I)...)
setindex!(V::View, v, I::Real...) = setindex!(V, v, to_index(I)...)

# Indexing with non-scalars. For now, this returns a copy, but changing that
# is just a matter of deleting the explicit call to copy.
 getindex(V::View, I::ViewIndex...) = copy(subview(V, I...))
# setindex!(V::View, X, I::ViewIndex...) = copy!(subview(V, I...), X)

@ngenerate N typeof(A) function setindex!(A::View, x, J::NTuple{N,Union(Real,AbstractVector)}...)
    @ncall N checkbounds A J
    @nexprs N d->(I_d = Base.to_index(J_d))
    if !isa(x, AbstractArray)
        @nloops N i d->(1:length(I_d)) d->(@inbounds j_d = Base.unsafe_getindex(I_d, i_d)) begin
            @inbounds (@nref N A j) = x
        end
    else
        X = x
        @ncall N Base.setindex_shape_check X I
        k = 1
        @nloops N i d->(1:length(I_d)) d->(@inbounds j_d = Base.unsafe_getindex(I_d, i_d)) begin
            @inbounds (@nref N A j) = X[k]
            k += 1
        end
    end
    A
end

# NP is parent dimensionality, Itypes is the tuple typeof(V.indexes)
# NP may not be equal to length(Itypes), because a view of a 2d matrix A
# can be constructed as V = A[5:13] or as V = A[2:4, 1:3, 1].
function index_generate(NP, Itypes, Vsym, Isyms)
    if isempty(Isyms)
        Isyms = Any[1]  # this handles the syntax getindex(V)
    end
    exhead = :nothing
    NV = 0
    for I in Itypes
        NV += !(I == Int)
    end
    if length(Isyms) < NV
        # Linear indexing in the last index
        n = NV - length(Isyms)
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
    L = length(Itypes)
    indexexprs = Array(Any, L)
    j = 0
    for i = 1:L
        if Itypes[i] <: Real # && L-i+1 > length(Isyms)-j  # consume Isyms if we're running out of V.indexes
            indexexprs[i] = :($Vsym.indexes[$i])
        else
            j += 1
            indexexprs[i] = :(ArrayViewsAPL.unsafe_getindex($Vsym.indexes[$i], $(Isyms[j])))  # TODO: make Range bounds-checking respect @inbounds
        end
    end
    # Append any extra indexes. Must be trailing 1s or it will cause a BoundsError.
    if L < NP && j < length(Isyms)
        # This view was created as V = A[5:13], so appending them would generate interpretive confusion.
        # Instead, use double-indexing, i.e., A[indexes1...][indexes2...], where indexes2 contains the leftovers.
        return exhead, :($Vsym.parent[$(indexexprs...)][$(Isyms[j+1:end]...)])
    end
    for k = j+1:length(Isyms)
        push!(indexexprs, Isyms[k])
    end
    exhead, :($Vsym.parent[$(indexexprs...)])
end

unsafe_getindex(v::Real, ind::Int) = v
unsafe_getindex(v::Range, ind::Int) = first(v) + (ind-1)*step(v)
unsafe_getindex(v::BitArray, ind::Int) = Base.unsafe_bitgetindex(v.chunks, ind)
unsafe_getindex(v::AbstractArray, ind::Int) = v[ind]
unsafe_getindex(v, ind::Real) = unsafe_getindex(v, to_index(ind))


## Merging indexes
# A view created like V = A[2:3:8, 5:2:17] can later be indexed as V[2:7],
# creating a new 1d view.
# In such cases we have to collapse the 2d space spanned by the ranges.
#
# API:
#    merge_indexes(indexes::NTuple, dims::Dims, linindex)
# where dims encodes the trailing dimensions of the parent array,
# indexes encodes the view's trailing indexes into the parent array,
# and linindex encodes the subset of these elements that we'll select.
#
# The generic algorithm makes use of div to convert elements
# of linindex into a cartesian index into indexes, looks up
# the corresponding cartesian index into the parent, and then uses
# dims to convert back to a linear index into the parent array.
#
# However, a common case is linindex::UnitRange.
# Since div is slow and in(j::Int, linindex::UnitRange) is fast,
# it can be much faster to generate all possibilities and
# then test whether the corresponding linear index is in linindex.
# One exception occurs when only a small subset of the total
# is desired, in which case we fall back to the div-based algorithm.
stagedfunction merge_indexes(indexes::NTuple, dims::Dims, linindex::UnitRange{Int})
    N = length(indexes)
    N > 0 || error("Cannot merge empty indexes")
    quote
        n = length(linindex)
        Base.Cartesian.@nexprs $N d->(I_d = indexes[d])
        L = 1
        Base.Cartesian.@nexprs $N d->(L *= length(I_d))
        if n < 0.1L   # this has not been carefully tuned
            return merge_indexes_div(indexes, dims, linindex)
        end
        Pstride_1 = 1   # parent strides
        Base.Cartesian.@nexprs $(N-1) d->(Pstride_{d+1} = Pstride_d*dims[d])
        Istride_1 = 1   # indexes strides
        Base.Cartesian.@nexprs $(N-1) d->(Istride_{d+1} = Istride_d*length(I_d))
        Base.Cartesian.@nexprs $N d->(counter_d = 1) # counter_0 is a linear index into indexes
        Base.Cartesian.@nexprs $N d->(offset_d = 1)  # offset_0 is a linear index into parent
        k = 0
        index = Array(Int, n)
        Base.Cartesian.@nloops $N i d->(1:length(I_d)) d->(offset_{d-1} = offset_d + (I_d[i_d]-1)*Pstride_d; counter_{d-1} = counter_d + (i_d-1)*Istride_d) begin
            if in(counter_0, linindex)
                index[k+=1] = offset_0
            end
        end
        index
    end
end
merge_indexes(indexes::NTuple, dims::Dims, linindex) = merge_indexes_div(indexes, dims, linindex)

# This could be written as a regular function, but performance
# will be better using Cartesian macros to avoid the heap and
# an extra loop.
stagedfunction merge_indexes_div(indexes::NTuple, dims::Dims, linindex)
    N = length(indexes)
    N > 0 || error("Cannot merge empty indexes")
    Istride_N = symbol("Istride_$N")
    quote
        Base.Cartesian.@nexprs $N d->(I_d = indexes[d])
        Pstride_1 = 1   # parent strides
        Base.Cartesian.@nexprs $(N-1) d->(Pstride_{d+1} = Pstride_d*dims[d])
        Istride_1 = 1   # indexes strides
        Base.Cartesian.@nexprs $(N-1) d->(Istride_{d+1} = Istride_d*length(I_d))
        n = length(linindex)
        L = $(Istride_N) * length(indexes[end])
        index = Array(Int, n)
        for i = 1:n
            k = linindex[i] # k is the indexes-centered linear index
            1 <= k <= L || throw(BoundsError())
            k -= 1
            j = 0  # j will be the new parent-centered linear index
            Base.Cartesian.@nexprs $N d->(d < $N ?
                begin
                    c, k = divrem(k, Istride_{$N-d+1})
                    j += (ArrayViewsAPL.unsafe_getindex(I_{$N-d+1}, c+1)-1)*Pstride_{$N-d+1}
                end : begin
                    j += ArrayViewsAPL.unsafe_getindex(I_1, k+1)
                end)
            index[i] = j
        end
        index
    end
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
## Compatability
# deprecate?
function parentdims(s::View)
    nd = ndims(s)
    dimindex = Array(Int, nd)
    sp = strides(s.parent)
    sv = strides(s)
    j = 1
    for i = 1:ndims(s.parent)
        r = s.indexes[i]
        if j <= nd && (isa(r,Range) ? sp[i]*step(r) : sp[i]) == sv[j]
            dimindex[j] = i
            j += 1
        end
    end
    dimindex
end

end
