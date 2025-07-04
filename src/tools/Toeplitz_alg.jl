# v 0.1 Nov 2020
# Part of the Eegle.jl package.
# Copyright Alexandre Bleuzé, University Grenoble Alpes.

module toeplitzAlgebra

using Base.Threads

export Toeplitz,
       Tn_time_Tn_transpose,
       Tn_time_X


# This module creates the Toeplitz matrix for estimating ERP means via
# multivariate regression method and performs operations using this
# matrix. See Congedo et al.(2016)
# `ns` is the number of samples
# `wl` is the window length, i.e., the ERPs duration, in samples
# `mark` (markers) is either
#       1) a vector of integers holding the (1-based) serial number
#       of the samples where there is the stimulation for a class (trials onset)
#       2) a vector of nc integer vectors as in 1), where nc is the
#       number of classes.
#       Typically, `mark` is created from a stimulation vector using the
#       'stim2mark' function of this module.
# Optional keyword arguments:
# `weights` can be used to obtain weighted means. It is either
#       1) a vector of non-negative real weights for the trials
#       2) a vector of nc vectors as in 1)
#       In both cases `weights` has the same dimension of `mark`.
#       The weights must be appropriately normalized (see 'mean' in this module).
#       By default, no weights are used.


## Structure that represents a toeplitz matrix.
#`shape` is the shape of the Toeplz matrix, wl(window length) x ns ( # samples).
#`mark` stores the indeces of the non-zero diagonals
#`weights` stores the value of the corresponding non-zero diagonals in 'mark'.
# Can be :none which means that all weights are equal to 1.
struct Toeplitz
        shape::Tuple{Int64,Int64}
        mark::Vector{Int64}
        weights::Union{Vector{Float64}, Symbol}
end

## Compute the multiplication of a toeplitz matrix by itself transposed.
#`T` is a Toeplitz with shape (wl, L) with wl the window length of a trial and L
#the total number of samples.
function T_time_T_transpose(T::Toeplitz)
        n = T.shape[1]
        first_row = zeros(n)
        if T.weights == :none
                @inbounds for marki = T.mark
                        for markj = T.mark
                                if marki<=markj<=marki+n-1
                                        first_row[markj-marki+1] += 1
                                end
                        end
                end
        else
                @inbounds for (weighti,marki) = zip(T.weights, T.mark)
                        for (weightj,markj) = zip(T.weights, T.mark)
                                if marki<=markj<=marki+n-1
                                        first_row[markj-marki+1] += weighti*weightj
                                end
                        end
                end
        end
        return(first_row)
end


function FirstRow2Matrix(row::Vector{Float64})
        n = length(row)
        M = zeros(n,n)
        for i = 1:n
                M[i,1:(i-1)] = M[1:(i-1),i]'
                M[i,i:n] = row[1:n-i+1]
        end
        return (M)
end


function T1_time_T2_transpose(T1::Toeplitz, T2::Toeplitz)
        n = T1.shape[1]
        mark_dico = Dict()
        if T1.weights == :none
                if T2.weights ==:none
                        @inbounds for (i,marki) in enumerate(T1.mark)
                                for (j,markj) in enumerate(T2.mark)
                                        if markj<=marki<=markj+n-1
                                                new_mark = marki-markj+1
                                                if new_mark ∈ keys(mark_dico)
                                                        mark_dico[new_mark] += 1.0
                                                else
                                                        mark_dico[new_mark] = 1.0
                                                end
                                        elseif marki<=markj<=marki+n-1
                                                new_mark = markj-marki+n
                                                if new_mark ∈ keys(mark_dico)
                                                        mark_dico[new_mark] += 1.0
                                                else
                                                        mark_dico[new_mark] = 1.0
                                                end
                                        end
                                end
                        end
                else
                        @inbounds for (i,marki) in enumerate(T1.mark)
                                for (j,markj) in enumerate(T2.mark)
                                        if markj<=marki<=markj+n-1
                                                new_mark = marki-markj+1
                                                if new_mark ∈ keys(mark_dico)
                                                        mark_dico[new_mark] += T2.weights[j]
                                                else
                                                        mark_dico[new_mark] = T2.weights[j]
                                                end
                                        elseif marki<=markj<=marki+n-1
                                                new_mark = markj-marki+n
                                                if new_mark ∈ keys(mark_dico)
                                                        mark_dico[new_mark] += T2.weights[j]
                                                else
                                                        mark_dico[new_mark] = T2.weights[j]
                                                end
                                        end
                                end
                        end
                end
        else
                if T2.weights ==:none
                        @inbounds for (i,marki) in enumerate(T1.mark)
                                for (j,markj) in enumerate(T2.mark)
                                        if markj<=marki<=markj+n-1
                                                new_mark = marki-markj+1
                                                if new_mark ∈ keys(mark_dico)
                                                        mark_dico[new_mark] += T1.weights[i]
                                                else
                                                        mark_dico[new_mark] = T1.weights[i]
                                                end
                                        elseif marki<=markj<=marki+n-1
                                                new_mark = markj-marki+n
                                                if new_mark ∈ keys(mark_dico)
                                                        mark_dico[new_mark] += T1.weights[i]
                                                else
                                                        mark_dico[new_mark] = T1.weights[i]
                                                end
                                        end
                                end
                        end
                else
                        @inbounds for (weighti,marki) in zip(T1.weights, T1.mark)
                                for (weightj,markj) in zip(T2.weights, T2.mark)
                                        if markj<=marki<=markj+n-1
                                                new_mark = marki-markj+1
                                                if new_mark ∈ keys(mark_dico)
                                                        mark_dico[new_mark] += weighti*weightj
                                                else
                                                        mark_dico[new_mark] = weighti*weightj
                                                end
                                        elseif marki<=markj<=marki+n-1
                                                new_mark = markj-marki+n
                                                if new_mark ∈ keys(mark_dico)
                                                        mark_dico[new_mark] += weighti*weightj
                                                else
                                                        mark_dico[new_mark] = weighti*weightj
                                                end
                                        end
                                end
                        end
                end
        end
        new_mark = Vector{Int64}([key for key in keys(mark_dico)])
        new_weights = Vector{Float64}([weights for weights in values(mark_dico)])
        new_T= Toeplitz((n,n), new_mark, new_weights)
        return(new_T)
end


function Toeplitz2Matrix(T::Toeplitz)
        (n,p) = T.shape
        M = zeros(T.shape)
        if T.weights == :none
                for (i,mark) in enumerate(T.mark)
                        if (mark <= p)
                                for i = 1:minimum([p+1-mark, n])
                                        M[i, mark-1+i] = 1
                                end
                        else
                                for i = 1:minimum([n+p-mark, p])
                                        M[mark-p+i, i] = 1
                                end
                        end
                end
        else
                for (i,mark) in enumerate(T.mark)
                        weights = T.weights[i]
                        if (mark <= p)
                                for i = 1:minimum([p+1-mark, n])
                                        M[i, mark-1+i] = weights
                                end
                        else
                                for i = 1:minimum([n+p-mark, p])
                                        M[mark-p+i, i] = weights
                                end
                        end
                end
        end
        return(M)
end

## Compute the multiplication of the concatenated toeplitz matrix by itself transposed.
#`Tn` is a vector of Toeplitz with shape (wl, p) with wl the window length of a
#trial and p the total number of samples. The toeplitz matrices are considered concatenated
function Tn_time_Tn_transpose(Tn::Vector{Toeplitz})
        K = length(Tn)
        n = Tn[1].shape[1]
        M = zeros(n*K,n*K)
        @inbounds for i = 1:K
                M[1+n*(i-1):n*i,1+n*(i-1):n*i] = FirstRow2Matrix(T_time_T_transpose(Tn[i]))
                 for j = (i+1):K
                        Tij = Toeplitz2Matrix(T1_time_T2_transpose(Tn[i], Tn[j]))
                        M[1+n*(i-1):n*i, 1+n*(j-1):n*j] = Tij
                        M[1+n*(j-1):n*j, 1+n*(i-1):n*i] = Tij'
                end
        end
        return(M)
end

function T_time_X(T::Toeplitz, X::Array{Float64})
        n1 = T.shape[1]
        M = zeros(Float64, n1, size(X, 2))
        if T.weights == :none
                for mark = T.mark
                        M += X[mark:mark+n1-1, :]
                end
        else
                for (mark, weight) = zip(T.mark, T.weights)
                        M += weight*X[mark:mark+n1-1, :]
                end
        end
        return(M)
end

## Compute the multiplication of the concatenated toeplitz matrix with the data matrix X.
#`Tn` is a vector of Toeplitz with shape (wl, L) with wl the window length of a
#trial and L the total number of samples. The toeplitz matrices are considered concatenated
#`X` is a data matrix with shape (L, N) with N the number of sensors
function Tn_time_X(Tn::Vector{Toeplitz}, X::Array{Float64})
        n_tot = 0
        for T = Tn
                n_tot += T.shape[1]
        end
        M = zeros(Float64, n_tot, size(X, 2))
        n_k = 1
        for T = Tn
                M[n_k:n_k+T.shape[1]-1, :] = T_time_X(T, X)
                n_k += T.shape[1]
        end
        return(M)
end

end # module
