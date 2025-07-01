# ¤-¤-¤-¤-¤-¤-¤-¤ TESTS EEGtomography.jl  ¤-¤-¤-¤-¤-¤-¤-¤ #
# Last Revision: 18 Nov 2019

# construct a random leadfield with 10 electroed and 40 voxels (120 components)
Ne, Nv=20, 3000
K = ℌ(Ne)*randn(Ne, Nv) # in common average reference!

# compute the non-regularized minimum norm transformation matrix
Tmn = minNorm(K)

# compute the non-regularized sLORETA transformation matrix
TsLor = sLORETA(K)

TeLor = eLORETA(K)

# check whether the solutions respect the measurement;
K*Tmn ≈ ℌ(size(K, 1)) ? println("\x1b[92m", "minimum norm respects the measurement\n") :
                         println("\x1b[92m", "minimum norm does not respect the measurement\n")

K*TsLor≈ℌ(size(K, 1)) ? println("\x1b[92m", "sLORETA respects the measurement\n") :
                         println("\x1b[92m", "sLORETA does not respect the measurement\n")

K*TeLor≈ℌ(size(K, 1)) ? println("\x1b[92m", "eLORETA respects the measurement\n") :
                         println("\x1b[92m", "eLORETA does not respect the measurement\n")


# compute the localization error by point spread functions.
# must be zero for the inverse solution to be acceptable.
println("\x1b[94m", "min norm: $(psfLocError(K, Tmn)) localization errors\n")
println("\x1b[94m", "sLORETA: $(psfLocError(K, TsLor)) localization errors\n")
println("\x1b[94m", "eLORETA: $(psfLocError(K, TeLor)) localization errors\n")

# Get the localization, spread and equalization errors
# for all voxels and all components for different solutions
Lmn, Smn, Qmn=psfErrors(K, Tmn)
LsLor, SsLor, QsLor=psfErrors(K, TsLor)
LeLor, SeLor, QeLor=psfErrors(K, TeLor)
