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
    As a MLM, the [MDM](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/mdm/) Riemannian classifier employing the affine-invariant (Fisher-Rao) metric is used ([barachant2012multi](@cite), [Congedo2017Review](@cite)).

    For each session, an 8-fold stratified cross-validation is run. The summary of results comprises the mean and standard deviation of the
    balanced accuracy obtained across the folds as well as the z-score and p-value of the cross-validation test-statistic — see [crval](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/cv/#PosDefManifoldML.crval) for details.

```julia
using Eegle # tell julia you want to use the Eegle package
```

First, declare a function for performing the cross-validation for both the MI and P300 paradigm, given arguments: 
- `file`: the full path of the sesson file on which the MLM is to be validated 
- `bandPass`: band-pass region for the filter to be applied to the data
- `upperLimit`: the only parameter for adaptive thresholding artifact-rejection, passed to [`reject`](@ref)
- `paradigm`: either `:MI` or `:P300`
- `covtype`: the desired covariance estimation for encoding trials, passed to [`encode`](@ref)
- `metric`: the desired metric for the MDM classifier
- `nFolds`: the number of stratified folds for the cross-validation, passed to `crval`.

```julia
function cv(file; bandPass, upperLimit, paradigm, covtype, metric, nFolds)

    println("File: ", file)
    
    #= To perform a cross-validation we need to 
    - read the session data,
    - encode the trials according to Riemannian geometry methodology
    - fit and evaluate a MDM Riemannian classifier in a stratified fold fashion
    =#

    # Read session data: Eegle.InOut.readNY
    o = readNY(file; bandPass, upperLimit, getTrials=["left_hand", "right_hand"]);

    # Trials encoding (a form of Covariance estimation): Eegle.CovarianceMatrix.encode
    𝐂 = encode(o, paradigm; covtype);

    # Cross-validation: PosDefManifoldML.crval
    cvRes = crval(MDM(metric), 𝐂, o.y; nFolds=8)

    return cvRes    
end

# optional keyword arguments for `cv`, which are common to the MI and P300 maradigm
args = (upperLimit = 1, covtype=LShrLW, 
        standardize = false, 
        metric = PosDefManifold.Fisher, 
        nFolds = 8)
```

Function `cv` return a [CVres](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/cv/#PosDefManifoldML.CVres) structure, which store the result of the cross-validation.

Next, declare a function to show a summary of the results given database `DB` and the associated vector `res` of `CVres` structures.  

```julia
function show_results(DB, res)
    println("Database: ", DB.dbName)
    println("mean and sd balanced accuracy, z and p-value against chance level")  
    for (i, r) ∈ res
        println("File ", i, ". mean(sd): ", r.avgAcc,"(", r.stdAcc,, "); ", 
                "z(p-value): ", r.z, "(", r.p, ")")
    end
    println("\n")
end
```

Finally, perform the cross-validation on all available MI databases featuring the `left_hand` and `right_hand` class, as

```julia
MIDir = joinpath(homedir(), "BCI Databases", "NY","MI") # path to MI databases
classes = ["left_hand", "right_hand"]
DBs = selectDB(MIDir, :MI; classes);

for (db, DB) ∈ enumerate(DBs)
    res = [cv(file; bandPass=(8, 32), getTrials=classes, args...) for file ∈ DB.files]
    show_results(DB, res)
end
```

or perform and cross-validation on all available P300 databases featuring at least 20 trials for both the `target` and `non-target` class, as


```julia
P300Dir = joinpath(homedir(), "BCI Databases", "NY","P300") # path to P300 databases
classes = ["target", "nontarget"]
DBs = selectDB(P300Dir, :P300; minTrials = 20, classes);

for (db, DB) ∈ enumerate(DBs)
    res = [cv(file; bandPass=(1, 24), getTrials=classes, args...) for file ∈ DB.files]
    show_results(DB, res)
end
```
