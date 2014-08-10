# ArrayViewsAPL

[![Build Status](https://travis-ci.org/timholy/ArrayViewsAPL.jl.svg?branch=master)](https://travis-ci.org/timholy/ArrayViewsAPL.jl)

This package is for developing array views based on staged functions, a new technology that will hopefully land in Julia 0.4.
Compared to previous efforts, staged functions perform almost all the "work" at compile time,
allowing the results of construction and indexing to typically result in a single-line expression.


### Comparison to ArrayViews and SubArrays

This effort is complementary to Dahua Lin's excellent [ArrayViews.jl](https://github.com/lindahua/ArrayViews.jl).
That package's great strength is making linear indexing efficient when the parent is an Array and when the view is contiguous.
The purposes of this package are (1) to handle any `AbstractArray`, (2) to focus on making cartesian indexing efficient, and (3) to optionally support slicing (i.e., dropping dimensions indexed with a scalar).

Aside from the differences in applicability and design, both approaches are very efficient.
Compared with ArrayViews, construction of the types here is even faster but linear indexing is not as fast.
An ideal solution would probably be to combine Dahua's ContiguousView type (to be used when applicable) with the approach here.

In base Julia, SubArrays are more general than the types used in ArrayViews, but they have a number of well-known performance problems. In particular, their generality makes them very slow to construct. Moreover, [SubArray indexing is delegated to linear indexing](https://github.com/JuliaLang/julia/blob/6b85f4e9129b846a0779d712c3ea33fa99929b36/base/subarray.jl#L194-L205), which is bad if the parent array type doesn't support efficient linear indexing.
In general, cartesian indexing can be made efficient for a wider variety of array types, which is why that approach is emphasized here.

### Benefits of stagedfunctions

As an example of the benefits of staged functions, consider making 2d slices of a 3d array,
```julia
S1 = sliceview(A, :, 5, :)
S2 = sliceview(A, 5, :, :)
```
For cartesian indexing, the natural approach is to replace `S1[i,j]` with `A[i,5,j]` and `S2[i,j]` with `A[5,i,j]`.
Doing so without any runtime overhead requires a method of `getindex` specialized for a `View{T,2,typeof(A),(UnitRange{Int},Int,UnitRange{Int})}` and a different one for a `View{T,2,typeof(A),(Int,UnitRange{Int},UnitRange{Int})}`. One could generate all these methods using loops, but supporting just `Int`, `UnitRange`, and `StepRange` up to dimension 8 would require 3^8 = 6561 pre-generated variants of `getindex`.
In contrast, staged functions allow all of these to be generated on the fly for arbitrary dimensionality.
This is quite desirable given that any given Julia session is likely to use just a very small fraction of these possible methods.

### Status

Much of the functionality is done, but this does not yet work due to [necessary fixes in staged functions](https://github.com/JuliaLang/julia/pull/7935).
To test it, you must be on the [`teh/staged`](https://github.com/timholy/julia/tree/teh/staged) branch of Julia,
which descends from the `kf/staged` branch with one additional fix and then rebased to a recent master.

Currently two types of view-creation are supported: `subview` and `sliceview`.
`subview` duplicates Julia's current indexing rules (including dropping trailing dimensions of size 1), and `sliceview` is aimed at full APL support (currently it behaves analogously to Julia's `slice`).
See also https://github.com/JuliaLang/julia/issues/5949.
