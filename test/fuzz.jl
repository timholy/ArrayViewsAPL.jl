using ArrayViewsAPL, Base.Test

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
