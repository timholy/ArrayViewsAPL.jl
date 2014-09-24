using ArrayViewsAPL
using Iterators, Base.Test

A = reshape(float64(1:300), 5, 5, 3, 4)
S = subview(A, 1:2, 1:2, 1:2, 1:2)
@test isa(S, View{Float64, 4})
@test size(S) == (2,2,2,2)
S = sliceview(A, 1:2, 1:2, 1:2, 1:2)
@test isa(S, View{Float64, 4})
@test size(S) == (2,2,2,2)
S = subview(A, 1:2, 1:2, 1:2, 2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},UnitRange{Int},Int)})
@test size(S) == (2,2,2)
S = sliceview(A, 1:2, 1:2, 1:2, 2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},UnitRange{Int},Int)})
@test size(S) == (2,2,2)
S = subview(A, 1:2, 1:2, 2, 1:2)
@test isa(S, View{Float64, 4, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},UnitRange{Int},UnitRange{Int})})
@test size(S) == (2,2,1,2)
S = sliceview(A, 1:2, 1:2, 2, 1:2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,UnitRange{Int})})
@test size(S) == (2,2,2)
P = S
S = subview(P, 1:2, 1:2, 1:2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,UnitRange{Int})})
@test size(S) == (2,2,2)
S = sliceview(P, 1:2, 1:2, 1:2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,UnitRange{Int})})
@test size(S) == (2,2,2)
S = subview(P, 1:2, 1:2, 2)
@test isa(S, View{Float64, 2, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,Int)})
@test size(S) == (2,2)
S = sliceview(P, 1:2, 1:2, 2)
@test isa(S, View{Float64, 2, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,Int)})
@test size(S) == (2,2)
S = subview(P, 1:2, 2, 1:2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,UnitRange{Int})})
@test size(S) == (2,1,2)
S = sliceview(P, 1:2, 2, 1:2)
@test isa(S, View{Float64, 2, Array{Float64,4}, (UnitRange{Int},Int,Int,UnitRange{Int})})
@test size(S) == (2,2)
S = subview(P, 2, 1:2, 1:2)
@test isa(S, View{Float64, 3, Array{Float64,4}, (UnitRange{Int},UnitRange{Int},Int,UnitRange{Int})})
@test size(S) == (1,2,2)
S = sliceview(P, 2, 1:2, 1:2)
@test isa(S, View{Float64, 2, Array{Float64,4}, (Int,UnitRange{Int},Int,UnitRange{Int})})
@test size(S) == (2,2)


A = reshape(1:75, 5, 5, 3)
# Copy the values to a subarray. Do this manually since getindex(A, ...) will have a new meaning
indexes1 = (2:4, 3, 1:2)
Aslice1 = Array(eltype(A), length(indexes1[1]), length(indexes1[3]))
i = 1
for p in product(indexes1...)
    Aslice1[i] = A[p...]
    i += 1
end
Asub1 = reshape(Aslice1, map(length, indexes1))
indexes2 = (2:4, 1:2, 3)
Aslice2 = Array(eltype(A), length(indexes2[1]), length(indexes2[2]))
i = 1
for p in product(indexes2...)
    Aslice2[i] = A[p...]
    i += 1
end
Asub2 = Aslice2  # drop the last singleton dimension

# sliceview
for (indexes,Aslice) in ((indexes1,Aslice1), (indexes2,Aslice2))
    B = sliceview(A, indexes...)
    @test ndims(B) == 2
    @test B[1,1] == Aslice[1,1]
    @test B[2,2] == Aslice[2,2]
    @test B[3] == Aslice[3]
    @test B[4] == Aslice[4]
    @test Aslice == B

    C = sliceview(B, 1:3, 1:2)
    @test C == B
    C = sliceview(B, 2:3, 2)
    @test ndims(C) == 1
    @test C[1] == B[2,2]
    @test C[2] == B[3,2]
    C = sliceview(B, 2, 1:2)
    @test ndims(C) == 1
    @test C[1] == B[2,1]
    @test C[2] == B[2,2]

    @test C[1,1] == B[2,1]
    @test_throws BoundsError C[1,2]
end

# subview
for (indexes,Asub) in ((indexes1,Asub1), (indexes2,Asub2))
    B = subview(A, indexes...)
    @show typeof(B)
    @test Asub == B

    C = subview(B, 1:3, 1, 1:2)
    @test C == B
    C = subview(B, 2:3, 1, 2)
    @test ndims(C) == 1
    @test C[1] == B[2,2]
    @test C[2] == B[3,2]
    C = subview(B, 2, 1, 1:2)
    @test ndims(C) == 3
    @test C[1] == B[2,1]
    @test C[2] == B[2,2]
end

