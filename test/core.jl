using Base.Test
using ArrayViewsAPL

A = reshape(float64(1:300), 5, 5, 3, 4)
S = subview(A, 1:2, 1:2, 1:2, 1:2)
@test isa(S, View{Float64, 4})
@test size(S) == (2,2,2,2)
@test strides(S) == (1,5,25,75)
S = sliceview(A, 1:2, 1:2, 1:2, 1:2)
@test isa(S, View{Float64, 4})
@test size(S) == (2,2,2,2)
@test strides(S) == (1,5,25,75)
S = subview(A, 1:2, 1:2, 1:2, 2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},UnitRange{Int},Int)})
@test size(S) == (2,2,2)
@test strides(S) == (1,5,25)
S = sliceview(A, 1:2, 1:2, 1:2, 2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},UnitRange{Int},Int)})
@test size(S) == (2,2,2)
@test strides(S) == (1,5,25)
S = subview(A, 1:2, 1:2, 2, 1:2)
@test isa(S, View{Float64, 4, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},UnitRange{Int},UnitRange{Int})})
@test size(S) == (2,2,1,2)
@test strides(S) == (1,5,25,75)
S = sliceview(A, 1:2, 1:2, 2, 1:2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,UnitRange{Int})})
@test size(S) == (2,2,2)
@test strides(S) == (1,5,75)
P = S
S = subview(P, 1:2, 1:2, 1:2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,UnitRange{Int})})
@test size(S) == (2,2,2)
@test strides(S) == (1,5,75)
S = sliceview(P, 1:2, 1:2, 1:2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,UnitRange{Int})})
@test size(S) == (2,2,2)
@test strides(S) == (1,5,75)
S = subview(P, 1:2, 1:2, 2)
@test isa(S, View{Float64, 2, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,Int)})
@test size(S) == (2,2)
@test strides(S) == (1,5)
S = sliceview(P, 1:2, 1:2, 2)
@test isa(S, View{Float64, 2, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,Int)})
@test size(S) == (2,2)
@test strides(S) == (1,5)
S = subview(P, 1:2, 2, 1:2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,UnitRange{Int})})
@test size(S) == (2,1,2)
@test strides(S) == (1,5,75)
S = sliceview(P, 1:2, 2, 1:2)
@test isa(S, View{Float64, 2, Array{Float64,4}, (UnitRange{Int},Int,Int,UnitRange{Int})})
@test size(S) == (2,2)
@test strides(S) == (1,75)
S = subview(P, 2, 1:2, 1:2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,UnitRange{Int})})
@test size(S) == (1,2,2)
@test strides(S) == (1,5,75)
S = sliceview(P, 2, 1:2, 1:2)
@test isa(S, View{Float64, 2, Array{Float64,4}, (Int,UnitRange{Int},Int,UnitRange{Int})})
@test size(S) == (2,2)
@test strides(S) == (5,75)

## 2d
# Whole-array views
A = reshape(1:24, 6, 4)
@test typeof(A[1:2,1:2]) == Array{Int, 2}  # so we won't be fooled when this changes
B = subview(A, 1:6, 1:4)
@test B[2] == A[2]
@test B[3,1] == A[3,1]
@test B[4,2,1] == A[4,2]
@test B == A
@test strides(B) == (1,6)
@test pointer(B) == pointer(A)
B = sliceview(A, 1:6, 1:4)
@test B == A
@test B[2] == A[2]
@test B[3,1] == A[3,1]
@test B[4,2,1] == A[4,2]
@test pointer(B) == pointer(A)
B = subview(A, :, :)
@test B == A
B = sliceview(A, :, :)
@test B == A
# Views with extra dimensions
B = subview(A, 1:6, 1:4, 1)
@test ndims(B) == 2
@test size(B) == (6,4)
@test strides(B) == (1,6)
@test B[7] == A[7]
@test B[6,4] == A[6,4]
@test B[3,3,1] == A[3,3]
@test B[4,2,1,1] == A[4,2]
@test B == A
B = sliceview(A, 1:6, 1:4, 1)
@test ndims(B) == 2
@test size(B) == (6,4)
@test strides(B) == (1,6)
@test B[7] == A[7]
@test B[6,4] == A[6,4]
@test B[3,3,1] == A[3,3]
@test B[4,2,1,1] == A[4,2]
@test B == A
B = subview(A, 1:6, 1:4, 2)
@test_throws BoundsError B[1,1]
@test_throws BoundsError B[1]
B = sliceview(A, 1:6, 1:4, 2)
@test_throws BoundsError B[1,1]
@test_throws BoundsError B[1]
# Partial views
B = subview(A, 2:2:6, 2)
@test ndims(B) == 1
@test strides(B) == (2,)
@test pointer(B) == pointer(A)+7*sizeof(Int)
@test B == [8:2:12]
@test B[1] == 8
@test B[1,1] == 8
@test B[3] == 12
@test B[3,1] == 12
B = sliceview(A, 2:2:6, 2)
@test ndims(B) == 1
@test pointer(B) == pointer(A)+7*sizeof(Int)
@test B == [8:2:12]
@test B[1] == 8
@test B[1,1] == 8
@test B[3] == 12
@test B[3,1] == 12
B = subview(A, 2, 2:4)
@test ndims(B) == 2
@test strides(B) == (1,6)
@test pointer(B) == pointer(A)+7*sizeof(Int)
@test B == A[2,2:4]
@test B[1] == 8
@test B[1,1] == 8
@test B[1,1,1] == 8
@test B[3] == 20
@test B[1,3] == 20
@test B[1,3,1] == 20
B = sliceview(A, 2, 2:4)
@test ndims(B) == 1
@test strides(B) == (6,)
@test pointer(B) == pointer(A)+7*sizeof(Int)
@test B == squeeze(A[2,2:4], 1)
@test B[1] == 8
@test B[1,1] == 8
@test B[1,1,1] == 8
@test B[3] == 20
@test B[3,1] == 20
# Views created with fewer dimensions (linear indexing)
B = subview(A, 5:13)
@test ndims(B) == 1
@test strides(B) == (1,)
@test pointer(B) == pointer(A) + 4*sizeof(Int)
@test B == [5:13]
@test B[1] == 5
@test B[9] == 13
@test B[2,1] == 6
@test B[8,1] == 12
B = sliceview(A, 5:13)
@test ndims(B) == 1
@test pointer(B) == pointer(A) + 4*sizeof(Int)
@test B == [5:13]
@test B[1] == 5
@test B[9] == 13
@test B[2,1] == 6
@test B[8,1] == 12
B = subview(A, 1:3:6, 2:2:4)
@test pointer(B) == pointer(A) + 6*sizeof(Int)
@test size(B) == (2,2)
@test strides(B) == (3,12)
@test B[1] == 7
@test B[3] == 19
@test B[2,1] == 10
@test B[2,2] == 22
@test B[1,2,1] == 19
# Flipped axes
B = subview(A, 5:-1:3, 1:4)
@test size(B) == (3,4)
@test strides(B) == (-1,6)
@test pointer(B) == pointer(A) + 4*sizeof(Int)
@test B[1,1] == A[5,1]
@test B[2] == A[4,1]
@test B[2,3,1] == A[4,3]
B = subview(A, 5:-1:3, 4:-2:1)
@test size(B) == (3,2)
@test strides(B) == (-1,-12)
@test pointer(B) == pointer(A) + 22*sizeof(Int)
@test B[1] == 23
@test B[5] == 10
@test B[3,1] == 21
@test B[2,2] == 10
@test B[3,2,1] == 9
# Views with Vector{Int}
B = subview(A, [1,3,4], 1:2:4)
@test B[2,2] == A[3,3]
@test_throws ErrorException strides(B)
@test_throws MethodError pointer(B)

I1 = 2:2:8
I2 = 5:3:12
dims = (13,)   # could supply a 2nd size, but it's not used so why bother
I12 = [54,56,58,60,93,95,97,99,132,134,136,138]
L = length(I12)
ind = ArrayViewsAPL.merge_indexes((I1, I2), dims, 1:L)
@test ind == I12
ind = ArrayViewsAPL.merge_indexes((I1, I2), dims, 3:7)
@test ind == I12[3:7]
ind = ArrayViewsAPL.merge_indexes_div((I1, I2), dims, 1:L)
@test ind == I12
ind = ArrayViewsAPL.merge_indexes_div((I1, I2), dims, 3:7)
@test ind == I12[3:7]

## 2d, views-of-views
# Whole-array views
B = subview(A, :, :)
C = subview(B, :, :)
@test C == A
C = sliceview(B, :, :)
@test C == A
# with extra indexes
C = subview(B, 1:6, 1:4, 1)
@test ndims(C) == 2
@test size(C) == (6,4)
@test strides(C) == (1,6)
@test pointer(C) == pointer(A)
@test C[2] == A[2]
@test C[3,2] == A[3,2]
@test C[4,3,1] == A[4,3]
C = sliceview(B, 1:6, 1:4, 1)
@test ndims(C) == 2
@test size(C) == (6,4)
@test strides(C) == (1,6)
@test pointer(C) == pointer(A)
@test C[2] == A[2]
@test C[3,2] == A[3,2]
@test C[4,3,1] == A[4,3]
C = subview(B, 1:6, 1:4, 2)
@test_throws BoundsError C[1]
C = subview(B, 1:6, 1:4, 1:1)
@test ndims(C) == 3
@test size(C) == (6,4,1)
@test strides(C) == (1,6,24)
@test pointer(C) == pointer(A)
@test C[2] == A[2]
@test C[3,2] == A[3,2]
@test C[4,3,1] == A[4,3]
C = sliceview(B, 1:6, 1:4, 1:1)
@test ndims(C) == 3
@test size(C) == (6,4,1)
@test strides(C) == (1,6,24)
@test pointer(C) == pointer(A)
@test C[2] == A[2]
@test C[3,2] == A[3,2]
@test C[4,3,1] == A[4,3]

# Views of partial views
# For this, we need a bigger A
A = reshape(1:13*14, 13, 14)
I1, I2 = 3:2:13, 4:3:11
B = subview(A, I1, I2)
As = A[I1, I2]
@test B == As
C = subview(B, 1:6, 1:3)
@test C == As
@test strides(C) == (2,13*3)
C = sliceview(B, 1:6, 1:3)
@test C == As
C = subview(B, 2:2:5, 2:3)
@test C == As[2:2:5, 2:3]
@test strides(C) == (4,13*3)
C = sliceview(B, 2:2:5, 2:3)
@test C == As[2:2:5, 2:3]
C = subview(B, 3:5, 1:2:3)
@test C == As[3:5, 1:2:3]
@test strides(C) == (2,13*6)
# With fewer indexes (linear indexing)
C = subview(B, 2:2:8)
@test ndims(C) == 1
@test size(C) == (4,)
@test_throws ErrorException strides(C)
@test C[1] == As[2]
@test C[2,1] == As[4]

# with extra indexes
C = sliceview(B, 1:6, 3, 1:1)
@test ndims(C) == 2
@test size(C) == (6,1)
@test strides(C) == (2,13*14)
@test C[2] == As[2,3]
@test C[4,1] == As[4,3]
@test C[3,1,1] == As[3,3]
@test unsafe_load(pointer(C)) == As[1,3]
