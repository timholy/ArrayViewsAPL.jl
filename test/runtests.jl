using ArrayViewsAPL
using Base.Test

A = reshape(1:75, 5, 5, 3)
Aslice = squeeze(A[2:4, 3, 1:2], 2)
B = View(A, 2:4, 3, 1:2)
@test B[1,1] == Aslice[1,1]
@test B[2,2] == Aslice[2,2]
@test B[3] == Aslice[3]
@test B[4] == Aslice[4]
@test Aslice == B
