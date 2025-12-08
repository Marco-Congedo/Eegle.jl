# Tutorial ML 2

A common task in [BCI](@ref "Acronyms") research is to test a machine learning model (MLM) on a large amount of real data.
This tutorial uses the [FII BCI corpus](@ref "FII BCI Corpus Overview") as an example.

If you did not download the corpus yet, do so before running this tutorial using the [`downloadDB`](@ref) function.

The tutorial shows how to

1. Select databases and sessions from the FII BCI Corpus according to:
    - BCI Paradigm (Motor Imagery or P300)
    - availability of specific classes
    - minimum number of trials per class
2. Run a cross-validation for all selected [sessions](@ref "session") in all selected [databases](@ref "database") and store the balanced accuracies obtained on all cross-validations

!!! info
    As a MLM, the [MDM](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/mdm/) Riemannian classifier employing the affine-invariant (Fisher-Rao) metric is used [barachant2012multi](@cite), [Congedo2017Review](@cite). As a covariance matrix estimator, the linear shrinkage estimator of [LedoitWolf2004](@cite) is used. These are state-of-the art settings used as default in **Eegle**. 

    For each session, an 8-fold stratified cross-validation is run. While doing computations, summary results per session will be printed, including the mean and standard deviation of the balanced accuracy obtained across the folds as well as the p-value of the cross-validation test-statistic.

---

Select all motor imagery databases in the *FII BCI Corpus* featuring the "feet" and "right_hand" class. 
Within these databases, select the sessions featuring at least 30 trials for each of these classes — see [selectDB](@ref).

```julia
classes = ["feet", "right_hand"];
DBs = selectDB(:MI; classes, minTrials = 30);
```

Create memory to store all accuracies.
```julia
MIacc = [zeros(length(DB.files)) for DB ∈ DBs];
```

Perform the cross-validation on all selected sessions for all selected databases:

```julia
for (db, DB) ∈ enumerate(DBs), (f, file) ∈ enumerate(DB.files)
    # perform cross-validation (using Eegle)
    cv = crval(file; upperLimit = 1.2, bandPass=(8, 32), classes)
     
    # store accuracy 
    MIacc[db][f] = cv.avgAcc

    # print a summary of the cv results
    println("\nDatabase ", DB.dbName, ", File ", f, 
        ": mean(sd) balanced accuracy ", round(cv.avgAcc*100, digits=2),
        "% (± ", round(cv.stdAcc*100, digits=2), "%); ", 
        "p-value ", round(cv.p; digits = 4))
end
```

Show all MI accuracies
```julia
[round.(db; digits=2) for db ∈ MIacc]
```

---------

Perform the cross-validation on all available P300 databases and on all sessions featuring at least 25 trials for both the `target` and `non-target` classes. For P300 there is no need to specify these two classes as they are the default:

```julia
P300acc = [zeros(length(DB.files)) for DB ∈ DBs];

DBs = selectDB(:P300; minTrials = 25);

for (db, DB) ∈ enumerate(DBs), (f, file) ∈ enumerate(DB.files)
    # perform cross-validation (using Eegle)
    cv = crval(file; upperLimit=1.2, bandPass=(1, 24))
     
    # store accuracy
    P300acc[db][f] = cv.avgAcc

    # print a summary of the cv results
    println("\nDatabase ", DB.dbName, ", File ", f, 
        ": mean(sd) balanced accuracy ", round(cv.avgAcc*100, digits=2),
        "% (± ", round(cv.stdAcc*100, digits=2), "%); ", 
        "p-value ", round(cv.p; digits = 4))
end
```

For all possible options in running cross-validations, see [`Eegle.BCI.crval`](@ref).

!!! tip
    Do not use Julia's `@threaded` macro in the internal loops above as by default function `crval` is already multi-threaded across folds.
