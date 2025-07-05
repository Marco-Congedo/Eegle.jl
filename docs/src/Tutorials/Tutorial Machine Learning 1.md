# Tutorial ML 1

A common task in [BCI](@ref "Acronyms") reasearch is to test a machine learning model (MLM) on a large amount of real data.
This tutorial uses the FII-BCI corpus in [NY format](@ref) as an example.

The tutorial shows how to

1. Select databases and sessions from the FII-BCI corpus accoording to:
    - BCI Paradigm (Motor Imagery or P300)
    - availability of specific classes
    - minimum number of trials per class
2. Run a cross-validation for all selected [sessions](@ref "session") in all selected [databases](@ref "database")
3. Show a summary of the cross-validation results for each session.


!!! info
    As a MLM, the [MDM](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/mdm/) Riemannian classifier employing the affine-invariant (Fisher-Rao) metric is used [barachant2012multi](@cite), [Congedo2017Review](@cite). As a covariance matrix estimator, the linear shrinkage estimator of [LedoitWolf2004](@cite) is used.

    For each session, an 8-fold stratified cross-validation is run. The summary of results comprises the mean and standard deviation of the
    balanced accuracy obtained across the folds as well as the z-score and p-value of the cross-validation test-statistic — see [crval](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/cv/#PosDefManifoldML.crval) for details.

---

```julia
using Eegle # tell julia you want to use the Eegle package
```

First, declare a function for performing the cross-validation for both the MI and P300 paradigm, given arguments: 
- `file`: the full path of the sesson file on which the MLM is to be validated 
- `paradigm`: either `:MI` or `:P300`
- `bandPass`: band-pass region for the filter to be applied to the data
- `upperLimit`: the only parameter for adaptive thresholding artifact-rejection, passed to [`reject`](@ref)
- `getTrials`: the classes on which you want to select the databases, train and test the classifier <!-- @Marco ajouté -->
- `covtype`: the desired covariance estimation for encoding trials, passed to [`encode`](@ref)
- `standardize` : standardize the data matrix(ces) before estimating the covariance. <!-- @Marco à modifier si voulu  -->
- `metric`: the desired metric for the MDM classifier
- `nFolds`: the number of stratified folds for the cross-validation, passed to `crval`.

```julia
function cv(file; paradigm, bandPass, upperLimit, getTrials, covtype, standardize, metric, nFolds) #@Marco oublie de quelques args, corrigé 

    println("File: ", file)
    
    #= To perform a cross-validation we need to 
    - read the session data,
    - encode the trials according to Riemannian geometry methodology
    - fit and evaluate a MDM Riemannian classifier in a stratified fold fashion
    =#

    # Read session data: Eegle.InOut.readNY
    o = readNY(file; bandPass, upperLimit, getTrials);

    # Trials encoding (a form of Covariance estimation): Eegle.BCI.encode @Marco different encoding for P300
    if paradigm == :MI
        𝐂 = encode(o; covtype, standardize);
    elseif paradigm == :P300
        𝐂 = encode(o; covtype=LShrLW, targetLabel="target", standardize);
    end

    # Cross-validation: PosDefManifoldML.crval
    cvRes = crval(MDM(metric), 𝐂, o.y; nFolds)

    return cvRes    
end;

# optional keyword arguments for `cv`, which are common to the MI and P300 paradigm
args = (upperLimit = 1, covtype=LShrLW, 
        standardize = false, 
        metric = PosDefManifold.Fisher, 
        nFolds = 8);
```

Function `cv` return a [CVres](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/cv/#PosDefManifoldML.CVres) structure, which store the result of the cross-validation.

Next, declare a function to show a summary of the results given database `DB` and the associated vector `res` of `CVres` structures.  

```julia
function show_results(DB, res) 
    println("Database: ", DB.dbName)
    println("mean and sd balanced accuracy, z and p-value against chance level")  
    for (i, r) ∈ enumerate(res) # @Marco ajout de enumerate car causer un bug, amélioration de l'affichage plus claire désormais
        println("File ", i, ". mean(sd): ", round(r.avgAcc*100, digits=2) ,"% (± ", round(r.stdAcc*100, digits=2), " %); ", 
                "z(p-value): ", round(r.z, digits=4), "(", r.p, ")")
    end
    println("\n")
end;
```

Finally, perform the cross-validation on all available MI databases featuring the `left_hand` and `right_hand` class, as

```julia
MIDir = joinpath(homedir(), "BCI Databases", "NY","MI") # path to MI databases
classes = ["feet", "right_hand"]
DBs = selectDB(MIDir, :MI; classes);

for (db, DB) ∈ enumerate(DBs)
    res = [cv(file; bandPass=(8, 32), paradigm=:MI, getTrials=classes, args...) for file ∈ DB.files] # @Marco oubli de paradigm ici, a été rajouté
    show_results(DB, res)
end
```

or perform and cross-validation on all available P300 databases featuring at least 20 trials for both the `target` and `non-target` class, as


```julia
P300Dir = joinpath(homedir(), "BCI Databases","NY","P300") # path to P300 databases
# @Marco quand le paradigm est P300, selectDB ne prend pas l'argument classes, 
# car elles ne changent jamais les deux sont toujours obligatoires (tu m'avais dis de faire ca au moment ou jai creer la fonction , 
# si on utilise classes avec P300 la fonction envoie un warning dans selectDB)
DBs = selectDB(P300Dir, :P300; minTrials = 20);

for (db, DB) ∈ enumerate(DBs)
    res = [cv(file; bandPass=(1, 24), paradigm=:P300, getTrials = true, args...) for file ∈ DB.files] # @Marco oubli de paradigm ici, a été rajouté
    show_results(DB, res)
end
```
