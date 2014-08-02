using ArrayViewsAPL
using Iterators, Base.Test

A = reshape(1:75, 5, 5, 3)
# Copy the values to a subarray. Do this manually since getindex(A, ...) will have a new meaning
indexes = (2:4, 3, 1:2)
Aslice = Array(eltype(A), length(indexes[1]), length(indexes[3]))
i = 1
for p in product(indexes...)
    Aslice[i] = A[p...]
    i += 1
end
B = View(A, 2:4, 3, 1:2)
@test B[1,1] == Aslice[1,1]
@test B[2,2] == Aslice[2,2]
@test B[3] == Aslice[3]
@test B[4] == Aslice[4]
@test Aslice == B

C = View(B, 1:3, 1:2)
@test C == B
C = View(B, 2:3, 2)
@test ndims(C) == 1
@test C[1] == B[2,2]
@test C[2] == B[3,2]
C = View(B, 2, 1:2)
@test ndims(C) == 1
@test C[1] == B[2,1]
@test C[2] == B[2,2]

@test C[1,1] == B[2,1]
@test_throws BoundsError C[1,2]
