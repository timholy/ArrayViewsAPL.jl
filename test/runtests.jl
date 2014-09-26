using ArrayViewsAPL, Base.Test

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

# 2d warmup
A = reshape(1:24, 6, 4)
B = subview(A, 1:6, 1:4)
@test B == A
@test strides(B) == (1,6)
@test pointer(B) == pointer(A)
B = sliceview(A, 1:6, 1:4)
@test B == A
@test pointer(B) == pointer(A)
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
B = subview(A, 5:-1:3, 4:-2:1)
@test size(B) == (3,2)
@test strides(B) == (-1,-12)
@test pointer(B) == pointer(A) + 22*sizeof(Int)
@test B[1] == 23
@test B[5] == 10
@test B[3,1] == 21
@test B[2,2] == 10
@test B[3,2,1] == 9
B = subview(A, [1,3,4], 1:2:4)
@test_throws ErrorException strides(B)
@test_throws MethodError pointer(B)

## Higher dimensional fuzz testing
A = reshape(1:625, 5, 5, 5, 5)
function test0(A)
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
end
test0(A)

if !isdefined(:eq_arrays_linear) # to make subsequent runs much faster
function eq_arrays_linear(S, B)
    length(S) == length(B) || error("length mismatch")
    alleq = true
    for j = 1:length(B)
        alleq &= S[j] == B[j]
    end
    @test alleq
    nothing
end
end

## Generic indexing
index_choices = (1,3,5,2:3,3:3,1:2:5,4:-1:2,1:5,[1,4,3])
function test1(n)
for i = 1:n
    ii = rand(1:length(index_choices), 4)
    indexes = index_choices[ii]
    B = A[indexes...]
    S = subview(A, indexes...)
    @test size(S) == size(B)
    eq_arrays_linear(S, B)
    S = sliceview(A, indexes...)
    @test size(S) == size(B)[[map(x->!isa(x,Int), indexes)...]]
    eq_arrays_linear(S, B)
end
end
test1(10^4)

index3_choices = (2,7,13,22,5:17,2:3:20,[18,14,9,11])
function test2(n)
indexes = Array(Any, 3)
for i = 1:n
    ii = rand(1:length(index_choices), 2)
    indexes[1] = index_choices[ii[1]]
    indexes[2] = index_choices[ii[2]]
    indexes[3] = index3_choices[rand(1:length(index3_choices))]
    B = A[indexes...]
    S = subview(A, indexes...)
    @test size(S) == size(B)
    eq_arrays_linear(S, B)
    S = sliceview(A, indexes...)
    @test size(S) == size(B)[[map(x->!isa(x,Int), indexes)...]]
    eq_arrays_linear(S, B)
end
end
test2(10^4)

index2_choices = (13,42,55,99,111,88:99,2:5:54,[72,38,37,101])
function test3(n)
indexes = Array(Any, 2)
for i = 1:n
    indexes[1] = index_choices[rand(1:length(index_choices))]
    indexes[2] = index2_choices[rand(1:length(index2_choices))]
    B = A[indexes...]
    S = subview(A, indexes...)
    @test size(S) == size(B)
    eq_arrays_linear(S, B)
    S = sliceview(A, indexes...)
    @test size(S) == size(B)[[map(x->!isa(x,Int), indexes)...]]
    eq_arrays_linear(S, B)
end
end
test3(10^4)

index1_choices = (25,63,128,344,599,121:315,43:51:600,[19,1,603,623,555,229])
function test4()
for indexes in index1_choices
    B = A[indexes]
    S = subview(A, indexes)
    @test size(S) == size(B)
    eq_arrays_linear(S, B)
    S = sliceview(A, indexes)
    @test size(S) == size(B)[[!isa(indexes,Int)]]
    eq_arrays_linear(S, B)
end
end
test4()

function randsubset(indexes1)
    n = length(indexes1)
    indexesnew = Array(Any, n)
    for i = 1:n
        I = indexes1[i]
        if isa(I, Int)
            indexesnew[i] = 1
        else
            k = length(I)
            r = rand()
            if r < 0.3
                l = rand(1:k)
                indexesnew[i] = rand(1:k, l)
            elseif r < 0.6
                indexesnew[i] = rand(1:k)
            else
                i1 = rand(1:k)
                i2 = rand(1:k)
                indexesnew[i] = i1 >= i2 ? (i1:-1:i2) : (i1:1:i2)
            end
        end
    end
    indexes2 = [indexes1[k][indexesnew[k]] for k = 1:n]
    indexesnew, indexes2
end

## Views of views
function test5(A, n)
for i = 1:n
    ii = rand(1:length(index_choices), ndims(A))
    indexes = index_choices[ii]
    indexesnew, indexescomposed = randsubset(indexes)
    B = A[indexescomposed...]
    S1 = subview(A, indexes...)
    S = subview(S1, indexesnew...)
    @test size(S) == size(B)
    eq_arrays_linear(S, B)
    S1 = sliceview(A, indexes...)
    T, N, P, IV = typeof(S1).parameters
    keepdim = [map(x->!(x<:Int), IV)...]
    S = sliceview(S1, indexesnew[keepdim]...)
    @test size(S) == size(B)[[map(x->!isa(x,Int), indexescomposed)...]]
    eq_arrays_linear(S, B)
end
end
# Test this one in just 3d because of the combinatorial explosion from views-of-views
A = reshape(1:125, 5, 5, 5)
test5(A, 10^5)  # peaks out at more than 2000 separate stagedfunction generation events
