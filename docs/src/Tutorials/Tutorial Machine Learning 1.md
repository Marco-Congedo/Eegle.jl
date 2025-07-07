# Tutorial ML 1

A common task in [BCI](@ref "Acronyms") reasearch is to test a machine learning model (MLM) on a large amount of real data.
This tutorial uses the FII-BCI corpus in [NY format](@ref) as an example.

The tutorial shows how to

1. Select databases and sessions from the FII-BCI corpus accoording to:
    - BCI Paradigm (Motor Imagery or P300)
    - availability of specific classes
    - minimum number of trials per class
2. Run a cross-validation for all selected [sessions](@ref "session") in all selected [databases](@ref "database") and show a summary of the cross-validation results for each session.

!!! info
    As a MLM, the [MDM](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/mdm/) Riemannian classifier employing the affine-invariant (Fisher-Rao) metric is used [barachant2012multi](@cite), [Congedo2017Review](@cite). As a covariance matrix estimator, the linear shrinkage estimator of [LedoitWolf2004](@cite) is used. All these are default settings. 

    For each session, an 8-fold stratified cross-validation is run. The summary of results comprises the mean and standard deviation of the
    balanced accuracy obtained across the folds as well as the z-score and p-value of the cross-validation test-statistic.

---

Tell julia you want to use the Eegle package

```julia
using Eegle 
```

Create a function to print the results. The function takes as arguments the serial number of the file in the database and the result of the cross-validation, which is a [CVres](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/cv/#PosDefManifoldML.CVres) structure.

```julia
pr(f, res) = println("File ", f, ". mean(sd): ", round(res.avgAcc*100, digits=2),
                        "% (± ", round(res.stdAcc*100, digits=2), " %); ", 
                        "z(p-value): ", round(res.z, digits=4), "(", res.p, ")")
```

Perform the cross-validation on all available MI databases featuring the `left_hand` and `right_hand` class (see [selectDB](@ref)):

```julia
MIDir = joinpath(homedir(), "FII corpus", "NY","MI") # path to MI databases
classes = ["feet", "right_hand"]
DBs = selectDB(MIDir, :MI; classes);

for (db, DB) ∈ enumerate(DBs)
    println("Database: ", DB.dbName)
    println("mean and sd balanced accuracy, z and p-value against chance level:")
    for (f, file) ∈ enumerate(DB.files)
        pr(f, crval(file; bandPass=(8, 32), getTrials=classes))
    end
    println("")
end
```

Perform the cross-validation on all available P300 databases featuring at least 25 trials for both the `target` and `non-target` (default) classes:

```julia
P300Dir = joinpath(homedir(), "FII corpus","NY","P300") # path to P300 databases
DBs = selectDB(P300Dir, :P300; minTrials = 25);

for (db, DB) ∈ enumerate(DBs)
    println("Database: ", DB.dbName)
    println("mean and sd balanced accuracy, z and p-value against chance level:")
    for (f, file) ∈ enumerate(DB.files)
        pr(f, crval(file; bandPass=(1, 24)))
    end
    println("")
end
```

For all possible options in running cross-validations, see [`crval`](@ref).
