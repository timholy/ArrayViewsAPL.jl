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

A = reshape(1:625, 5, 5, 5, 5)
## Indexing to extract a scalar
# Linear indexing
for i = 5:7:400
    S = subview(A, i)
    @test S[1] == A[i]
    S = sliceview(A, i)
    @test S[1] == A[i]
end
# Linear indexing in trailing dimensions
for j = 10:13:125, i = 1:5
    S = subview(A, i, j)
    @test S[1] == A[i, j]
    S = sliceview(A, i, j)
    @test S[1] == A[i, j]
end
for k = 3:2:25, j = 1:5, i = 1:5
    S = subview(A, i, j, k)
    @test S[1] == A[i, j, k]
    S = sliceview(A, i, j, k)
    @test S[1] == A[i, j, k]
end
# Scalar indexing
for l = 1:5, k = 1:5, j = 1:5, i = 1:5
    S = subview(A, i, j, k, l)
    @test S[1] == A[i,j,k,l]
    S = sliceview(A, i, j, k, l)
    @test S[1] == A[i,j,k,l]
end

## Generic indexing
index_choices = (1,3,5,2:3,1:2:5,1:5,[1,4,3])
for i = 1:100
    ii = rand(1:length(index_choices), 4)
    indexes = index_choices[ii]
    B = A[indexes...]
    S = subview(A, indexes...)
    for j = 1:length(B)
        @test S[j] == B[j]
    end
    @test size(S) == size(B)
    S = sliceview(A, indexes...)
    for j = 1:length(B)
        @test S[j] == B[j]
    end
end
index3_choices = (2,7,13,22,5:17,2:3:20,[18,14,9,11])
indexes = Array(Any, 3)
for i = 1:100
    ii = rand(1:length(index_choices), 2)
    indexes[1] = index_choices[ii[1]]
    indexes[2] = index_choices[ii[2]]
    indexes[3] = index3_choices[rand(1:length(index3_choices))]
    B = A[indexes...]
    S = subview(A, indexes...)
    for j = 1:length(B)
        @test S[j] == B[j]
    end
    @test size(S) == size(B)
    S = sliceview(A, indexes...)
    for j = 1:length(B)
        @test S[j] == B[j]
    end
end
index2_choices = (13,42,55,99,111,88:99,2:5:54,[72,38,37,101])
indexes = Array(Any, 2)
for i = 1:100
    indexes[1] = index_choices[rand(1:length(index_choices))]
    indexes[2] = index2_choices[rand(1:length(index2_choices))]
    B = A[indexes...]
    S = subview(A, indexes...)
    for j = 1:length(B)
        @test S[j] == B[j]
    end
    @test size(S) == size(B)
    S = sliceview(A, indexes...)
    for j = 1:length(B)
        @test S[j] == B[j]
    end
end
index1_choices = (25,63,128,344,599,121:315,43:51:600,[19,1,603,623,555,229])
for indexes in index1_choices
    B = A[indexes]
    S = subview(A, indexes)
    for j = 1:length(B)
        @test S[j] == B[j]
    end
    @test size(S) == size(B)
    S = sliceview(A, indexes)
    for j = 1:length(B)
        @test S[j] == B[j]
    end
end


#=    
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
    @show indexes
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
=#
