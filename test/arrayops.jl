using ArrayViewsAPL, Base.Test

# subview
A = reshape(1:120, 3, 5, 8)
sA = subview(A, 2, 1:5, :)
@test parent(sA) == A
@test parentindexes(sA) == (2:2, 1:5, 1:8)
@test Base.parentdims(sA) == [1:3]
@test size(sA) == (1, 5, 8)
@test_throws BoundsError sA[2, 1:8]
@test sA[1, 2, 1:8][:] == [5:15:120]
sA[2:5:end] = -1
@test all(sA[2:5:end] .== -1)
@test all(A[5:15:120] .== -1)
@test strides(sA) == (1,3,15)
@test stride(sA,3) == 15
@test stride(sA,4) == 120
sA = subview(A, 1:3, 1:5, 5)
@test Base.parentdims(sA) == [1:2]
sA[1:3,1:5] = -2
@test all(A[:,:,5] .== -2)
sA[:] = -3
@test all(A[:,:,5] .== -3)
@test strides(sA) == (1,3)
sA = subview(A, 1:3, 3, 2:5)
@test Base.parentdims(sA) == [1:3]
@test size(sA) == (3,1,4)
@test sA == A[1:3,3,2:5]
@test sA[:] == A[1:3,3,2:5][:]
sA = subview(A, 1:2:3, 1:3:5, 1:2:8)
@test Base.parentdims(sA) == [1:3]
@test strides(sA) == (2,9,30)
@test sA[:] == A[1:2:3, 1:3:5, 1:2:8][:]

# subview logical indexing #4763
A = subview([1:10], 5:8)
@test A[A.<7] == [5, 6]
B = reshape(1:16, 4, 4)
sB = subview(B, 2:3, 2:3)
@test sB[sB.>8] == [10, 11]

# sliceview
A = reshape(1:120, 3, 5, 8)
sA = sliceview(A, 2, :, 1:8)
@test parent(sA) == A
@test parentindexes(sA) == (2, 1:5, 1:8)
@test Base.parentdims(sA) == [2:3]
@test size(sA) == (5, 8)
@test strides(sA) == (3,15)
@test sA[2, 1:8][:] == [5:15:120]
@test sA[:,1] == [2:3:14]
@test sA[2:5:end] == [5:15:110]
sA[2:5:end] = -1
@test all(sA[2:5:end] .== -1)
@test all(A[5:15:120] .== -1)
sA = sliceview(A, 1:3, 1:5, 5)
@test Base.parentdims(sA) == [1:2]
@test size(sA) == (3,5)
@test strides(sA) == (1,3)
sA = sliceview(A, 1:2:3, 3, 1:2:8)
@test Base.parentdims(sA) == [1,3]
@test size(sA) == (2,4)
@test strides(sA) == (2,30)
@test sA[:] == A[sA.indexes...][:]

a = [5:8]
@test parent(a) == a
@test parentindexes(a) == (1:4,)

# # Out-of-bounds construction. See #4044
# A = rand(7,7)
# rng = 1:4
# sA = subview(A, 2, rng-1)
# @test_throws BoundsError sA[1,1]
# @test sA[1,2] == A[2,1]
# sA = subview(A, 2, rng)
# B = subview(sA, 1, rng-1)
# C = subview(B, 1, rng+1)
# @test C == sA
# sA = sliceview(A, 2, rng-1)
# @test_throws BoundsError sA[1]
# @test sA[2] == A[2,1]
# sA = sliceview(A, 2, rng)
# B = sliceview(sA, rng-1)
# C = subview(B, rng+1)
# @test C == sA

# issue #6218 - logical indexing
A = rand(2, 2, 3)
msk = ones(Bool, 2, 2)
msk[2,1] = false
sA = subview(A, :, :, 1)
sA[msk] = 1.0
@test sA[msk] == ones(countnz(msk))


# of a subarray
a = rand(5,5)
s = subview(a,2:3,2:3)
# p = permutedims(s, [2,1])
# @test p[1,1]==a[2,2] && p[1,2]==a[3,2]
# @test p[2,1]==a[2,3] && p[2,2]==a[3,3]

## large matrices transpose ##

for i = 1 : 3
    a = rand(200, 300)
    @test isequal(a', permutedims(a, [2, 1]))
end

begin
    local A, A1, A2, A3, v, v2, cv, cv2, c, R, T

    A = rand(4,4)
    for s in {A[1:2:4, 1:2:4], subview(A, 1:2:4, 1:2:4)}
        c = cumsum(s, 1)
        @test c[1,1] == A[1,1]
        @test c[2,1] == A[1,1]+A[3,1]
        @test c[1,2] == A[1,3]
        @test c[2,2] == A[1,3]+A[3,3]

        c = cumsum(s, 2)
        @test c[1,1] == A[1,1]
        @test c[2,1] == A[3,1]
        @test c[1,2] == A[1,1]+A[1,3]
        @test c[2,2] == A[3,1]+A[3,3]
    end
end

# fill
@test fill!(Array(Float64,1),-0.0)[1] === -0.0
A = ones(3,3)
S = subview(A, 2, 1:3)
fill!(S, 2)
S = subview(A, 1:2, 3)
fill!(S, 3)
@test A == [1 1 3; 2 2 3; 1 1 1]
rt = Base.return_types(fill!, (Array{Int32, 3}, Uint8))
@test length(rt) == 1 && rt[1] == Array{Int32, 3}
