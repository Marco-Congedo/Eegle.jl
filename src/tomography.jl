# Model Driven and Data Driven weighted minimum norm, sLORETA and eLORETA
# vector type inverse solutions for EEG
# v 0.2 Oct 2024 (v0.1 Nov 2019)
# Part of the Eegle.jl package.
# Copyright Marco Congedo, CNRS, University Grenoble Alpes.

# ¤-¤-¤-¤-¤-¤-¤-¤ CONTENT ¤-¤-¤-¤-¤-¤-¤-¤ #

# centeringMatrix | common average reference operator (alias: ℌ)
# c2cd            | current density vector given a current vector
# psfLocError     | point spread function localization error
# minnorm         | minimum norm transformation Matrix
# sLORETA         | sLORETA transformation Matrix
# eLORETA         | eLORETA transformation Matrix

module Tomography

using LinearAlgebra, Statistics

# Module REPL text colors
const titleFont     = "\x1b[95m"
const separatorFont = "\x1b[35m"
const defaultFont   = "\x1b[0m"
const greyFont      = "\x1b[90m"


export
  centeringMatrix, ℌ,
  c2cd,
  psfLocError,
  psfErrors,
  minNorm,
  sLORETA,
  eLORETA


# centering matrix (H) of dimension Ne x Ne (common average reference operator).
# given a vector of data x or a leadfield k, H*x and H*k are centered.
# The result can also be found as [i==j ? 1.0-(1/Ne) : -1/Ne for i = 1:Ne, j = 1:Ne]
centeringMatrix(Ne::Int) = I-1/Ne*(ones(Ne)*ones(Ne)')
ℌ=centeringMatrix # alias for function centeringMatrix


# 'current to current density'
# return the current density vector (x²+y²+z²) given a current vector
c2cd(c::Vector{R}) where R<:Real =
  if rem(length(c), 3)≠0
    @warn "function `c2cd`: the length of the input vector is not a mutiple of 3." length(c)
  else
    [c[(i-1)*3+1]^2 + c[(i-1)*3+2]^2 + c[(i-1)*3+3]^2 for i = 1:length(c)÷3]
  end


# 'point spread function Localization Error'
# return the number of localization errors obtained by point spread functions
# given a leadfield matrix `K` and a corresponding transformation matrix `T`.
# For each column of the leadfield
psfLocError(K::Matrix{R}, T::Matrix{R}) where R<:Real =
    sum(findmax(c2cd(T*K[:, i]))[2]≠(i-1)÷3+1 for i = 1:size(K, 2))

    
# 'point spread function Errors'
# return the 3-tuple of vectors holding errors obtained at each voxel and
# each component (x, y, z)
# 1) Localization errors (bool)
#           true if the maximum cd is not located in the test location.
# 2) Spread errors (Float)
#           log(sum of cd everywhere/cd in the test location)
# 2) Equalization errors (Float)
#           uncorrected variance of the cd across all locations
function psfErrors(K::Matrix{R}, T::Matrix{R}) where R<:Real
   Nv✖3 = size(K, 2)
   loc=Vector{Bool}(undef, Nv✖3)
   spr=Vector{Float64}(undef, Nv✖3)
   equ=Vector{Float64}(undef, Nv✖3)

   for i=1:Nv✖3
     c=c2cd(T*K[:, i])
     loc[i]=findmax(c)[2]≠(i-1)÷3+1
     spr[i]=log(sum(c)/c[(i-1)÷3+1])
     equ[i]=var(c, corrected=false)
   end

    return loc, spr, equ
end

# Given a Ne x Nv✖3 leadfield matrix, where Ne is the number of electrodes
# and Nv✖3 the number of voxels times 3 (the x, y, z source components)
# return the minimum norm regularized transfer matrix with regularization `α`.
# if `C` is `:modelDriven` (default), compute the model driven solution,
# otherwise `C` must be the data covariance matrix and in this case compute the
# data-driven solution.
# if optional keyword argument `W` is a vector of Nv✖3 non-negative weights
# compute the weighted min norm regularized solution. In this case `C` must be
# equal to `:modelDriven` (default), as a weighted data-driven solution is not
# defined.
# NB if passed as a matrix, `C` must be non-singular. No check is performed.
# NB the columns of the leadfield matrix must be centered (common average ref.)
function minNorm(K::Matrix{R},
                 α::Real=0.,
                 C::Union{Symbol, Matrix{R}}=:modelDriven;
                 W::Union{Vector{R}, Nothing}=nothing) where R<:Real

  Ne, Nv✖3 = size(K)
  if W isa Vector{R}
    if length(W)≠Nv✖3
      @warn "function Loreta.minimunNorm: the length of weight vector `W` is different from the number of columns of leadfield matrix k" length(W) size(K, 2)
      return
    end

    if α<=0.
      @warn "function Loreta.minimunNorm: a weighted minimum norm solution can be obtained only for `α` positive" α
      return
    end

    if C isa Matrix{R}
      @warn "function Loreta.minimunNorm: cannot apply weight to a data-driven solution. Weights will be ignored"
      W=nothing
    end
  end

  if W isa Vector{R}
    w=inv.(W)
    return α<=0. ? (w.*K')*pinv(K*(w.*K')) : (w.*K')*pinv(K*(w.*K')+α*ℌ(Ne))
  else
    return α<=0. ? (C==:modelDriven ? pinv(K) : K'*inv(C)) :
                  (C==:modelDriven ? K'*inv(K*K'+α*ℌ(Ne)) : K'*inv(C+α*ℌ(Ne)))
  end
end



# Given a Ne x Nv✖3 leadfield matrix, where Ne is the number of electrodes
# and Nv✖3 the number of voxels times 3 (the x, y, z source components)
# return the sLORETA regularized transfer matrix with regularization `α`.
# if `C` is `:modelDriven` (default), compute the model driven solution,
# otherwise `C` must be the data covariance matrix and in this case compute the
# data-driven solution (similar to the linearly constrained min var beamformer).
# NB if passed as a matrix, `C` must be non-singular. No check is performed.
# NB the columns of the leadfield matrix must be centered (common average ref.)
function sLORETA(K::Matrix{R},
                 α::Real=0.,
                 C::Union{Symbol, Matrix{R}}=:modelDriven) where R<:Real
  (Ne, Nv✖3), Nv = size(K), size(K, 2)÷3
  T = Matrix{eltype(K)}(undef, Nv✖3, Ne) # allocate memory for the output

  α<=0. ? (C==:modelDriven ? Z = pinv(K*K') : Z = pinv(C)) :
          (C==:modelDriven ? Z = pinv(K*K'+α*ℌ(Ne)) : Z = pinv(C+α*ℌ(Ne)))
  @inbounds for v = 1:Nv
      L = K[:, (v-1)*3+1:v*3]
      T[(v-1)*3+1:v*3, :] = (√inv(L'*Z*L)) * (L'*Z)
  end

  return T
end


# Given a Ne x Nv✖3 leadfield matrix, where Ne is the number of electrodes
# and Nv✖3 the number of voxels times 3 (the x, y, z source components)
# return the eLORETA regularized transfer matrix with regularization `α`.
# if `C` is `:modelDriven` (default), compute the model driven solution,
# otherwise `C` must be the data covariance matrix and in this case compute the
# data-driven solution (similar to the linearly constrained min var beamformer).
# The model-driven solution is iterative; the convergence at each iteration
# is printed unless optional keyword argument `⍰` is set to false.
# `tol` is the tolerance for establishing convergence; it defaults to
# the square root of `Base.eps` of the nearest type of the elements of `K`.
# This corresponds to requiring the average norm of the difference between
# the 3x3 diagonal blocks of the weight matrix in two successive iterations
# to vanish for about half the significant digits.
# NB if passed as a matrix, `C` must be non-singular. No check is performed.
# NB the columns of the leadfield matrix must be centered (common average ref.)
function eLORETA(K::Matrix{R},
                 α::Real=0.,
                 C::Union{Symbol, Matrix{R}}=:modelDriven,
                 tol::Real=0.,
                 ⍰=true) where R<:Real

  KWKt(Nv::Int, 𝗞::Vector{Matrix}, 𝗪::Vector{Matrix}) =
       sum(𝗞[v]*𝗪[v]*𝗞[v]' for v=1:Nv)

  # get variables, memory and split leadfield in the leadfield for each voxel
  (Ne, Nv✖3), Nv = size(K), size(K, 2)÷3
  𝗪 = Vector{Matrix}(undef, Nv);
  💡, 𝗞 = similar(𝗪), similar(𝗪)
  @inbounds for v=1:Nv 𝗞[v]=K[:, (v-1)*3+1:v*3] end
  T = Matrix{R}(undef, Nv✖3, Ne) # allocate memory for the output

  if C==:modelDriven
    # initialization for iterations
    @inbounds for v = 1:Nv 𝗪[v] = Matrix{R}(I, 3, 3) end
    iter=1
    maxiter=300
    tol==0 ? tolerance = √eps(real(R)) : tolerance = tol

    # iterations
    while true
      Y=(α<=0. ? pinv(KWKt(Nv, 𝗞, 𝗪)) : pinv(KWKt(Nv, 𝗞, 𝗪)+α*ℌ(Ne)))
      @inbounds for v = 1:Nv 💡[v] = (√pinv(𝗞[v]'*Y*𝗞[v])) end
      conv=sum(norm(𝗪[v]-💡[v])/Nv for v=1:Nv)
      ⍰ && println("iteration: ", iter, "; convergence: ", conv)
        (overRun = iter == maxiter) && @warn "function LORETA.eLORETA reached the max number of iterations before convergence:", iter
        (converged = conv <= tolerance) || overRun==true ? break :
            @inbounds for v = 1:Nv 𝗪[v]=💡[v] end
        iter += 1
    end # while

  else
    # compute the 3x3 blocks of the weight matrix
    α<=0. ? Z=pinv(C) : Z = pinv(C+α*ℌ(Ne))
    @inbounds for v = 1:Nv 𝗪[v] = (√pinv(𝗞[v]'*Z*𝗞[v])) end
  end

  # compute weighted min norm solution with 3x3 block of of the weight matrix
  Y=(α<=0. ? pinv(KWKt(Nv, 𝗞, 𝗪)) : pinv(KWKt(Nv, 𝗞, 𝗪)+α*ℌ(Ne)))
   @inbounds for v = 1:Nv T[(v-1)*3+1:v*3, :] = (𝗪[v]*𝗞[v]')*Y end
  return T
end

end # module

#=
# ¤-¤-¤-¤-¤-¤-¤-¤ EXAMPLES OF REAL USAGE  ¤-¤-¤-¤-¤-¤-¤-¤ #

# number of electrodes, data samples, voxels
Ne, Ns, Nv=20, 200, 3000

# fake leadfield in common average reference
K = ℌ(Ne)*randn(Ne, Nv)

# fake data
X=randn(Ne, Ns)

# sample covariance matrix of the fake data
C=(1/Ns)*(X*X')

# fake weights for weighted minimum norm solutions
weights=abs.(randn(Nv))


Tmn = minNorm(K, 1)    # unweighted model-driven min norm with α=1
Tmn = minNorm(K, 10)   # unweighted model-driven min norm with α=10
Tmn = minNorm(K, 1; W=weights) # weighted model-driven min norm with α=1
Tmn = minNorm(K, 1, C) # data-driven min norm with α=1

TsLor = sLORETA(K, 1)     # model-driven sLORETA with α=1
TsLor = sLORETA(K, 10)    # model-driven sLORETA with α=10
TsLor = sLORETA(K, 1, C)  # data-driven sLORETA with α=1

TeLor = eLORETA(K, 1)     # model-driven eLORETA with α=1
TeLor = eLORETA(K, 10)    # model-driven eLORETA with α=10
TeLor = eLORETA(K, 1, C)  # data-driven eLORETA with α=1

=#
