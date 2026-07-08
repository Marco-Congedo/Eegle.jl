# Tutorial ML 2

[💻 Full Code](@ref "Code for Tutorial ML 2")

A common task in [BCI](@ref "Acronyms") research is to test a *machine learning model* (MLM) on a large amount of real data.
This tutorial uses the [FII BCI corpus](@ref "FII BCI Corpus Overview") to carry out such a task.

> ❗If you did not download the corpus yet, do so before running this tutorial using the [`downloadDB`](@ref) function.

The tutorial shows how to

1. Select databases and sessions from the FII BCI Corpus according to:
    - BCI Paradigm (Motor Imagery for this example)
    - availability of specific classes
    - minimum number of trials per class

2. Run a cross-validation for all selected [sessions](@ref "session") in all selected [databases](@ref "database") and store the balanced accuracies obtained on all cross-validations

3. Compute the average balanced accuracy within each database using an appropriate weighting function.

!!! info
    As a MLM, the [MDM](https://marco-congedo.github.io/PosDefManifoldML.jl/stable/mdm/) Riemannian classifier employing the affine-invariant (Fisher-Rao) metric is used [barachant2012multi](@cite). As a covariance matrix estimator, the linear shrinkage estimator of [LedoitWolf2004](@cite) is used. These are state-of-the art settings used as default in **Eegle**. 

    For each session, an 8-fold stratified cross-validation is run. While doing computations, summary results per session will be printed, including the mean and standard deviation of the balanced accuracy obtained across the folds as well as the p-value of the cross-validation test-statistic.

![](../assets/banner_ML.png)

Tell julia to use **Eegle**

```julia
using Eegle
```

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
    println("\nDatabase ", DB.dbName,"-", DB.condition,  ", File ", f, 
        ": mean(sd) balanced accuracy ", round(cv.avgAcc*100, digits=2),
        "% (± ", round(cv.stdAcc*100, digits=2), "%); ", 
        "p-value ", round(cv.p; digits = 4))
end
```

Show all MI accuracies
```julia
allMIacc = [round.(db; digits=3) for db ∈ MIacc]
```

Create appropriate weights to average the balanced accuracy within each database
using the [`weightsDB`](@ref) function and compute the weighted average balanced accuracy within each database. 

```julia
MIw = [weightsDB(db.files)[1] for db ∈ DBs]; # get weights
MIw = [w ./= mean(w) for w ∈ Miw]; # normalize to unit mean

MIdbAcc = [mean(w.*acc) for (w, acc) ∈ zip(MIw, allMIacc)]
```

!!! tip
    In julia, the ';' symbol at the end of a line does not print the output

The output you will see:

```repl
7-element Vector{Float64}:
 0.8011111111111111
 0.8283333333333331
 0.762857142857143
 0.830615454071332
 0.8523076923076922
 0.7055555555555555
 0.8743571862516337
```

For all possible options in running cross-validations, see [`Eegle.BCI.crval`](@ref).

!!! tip
    Do not use Julia's `@threaded` macro in the internal loops above as by default function `crval` is already multi-threaded across folds.

***
#### Code for Tutorial ML 2

```@example
using Eegle # hide
parseTutorial("Tutorial Machine Learning 2") # hide
```

[⬆️ Go to Top  ](@ref "Tutorial ML 2")
[🥳 More Tutorials](@ref "Tutorials")