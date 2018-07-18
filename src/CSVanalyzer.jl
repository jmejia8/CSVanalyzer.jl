module CSVanalyzer

import DataFrames: DataFrame
import HypothesisTests: pvalue, SignedRankTest

export statitistic,printSummary,statsToLatex,getComparison,comparisonToLatex

function statitistic(M::Matrix{Float64}; mapping::Function=identity)
    # rows = funs
    # cols = runs

    result = zeros(size(M,1), 5)
    for i = 1:size(M,1)
        x = mapping(M[i,:])
        
        result[i, 1] = minimum(x)
        result[i, 2] = median(x)
        result[i, 3] = mean(x)
        result[i, 4] = maximum(x)
        result[i, 5] = std(x)
    end

    return result
end


function printSummary(stats::Matrix{Float64}; mapping::Function=identity)
    for i = 1:size(stats,1)        
        @printf("Best = %.4e  Median = %.4e  Mean = %.4e  Worst = %.4e  std = %.4e\n",
                    stats[i, 1],
                    stats[i, 2],
                    stats[i, 3],
                    stats[i, 4],
                    stats[i, 5])
    end
end

function statsToLatex(stats::Matrix{Float64}; mapping::Function=identity)
 
    println("fn & Best &  Median &  Mean &  Worst &  Std. \\\\ \n")
 
    for i = 1:size(stats,1)        
        @printf("%d & %.4e & %.4e & %.4e & %.4e & %.4e \\\\ \\hline \n", i,
                    stats[i, 1],
                    stats[i, 2],
                    stats[i, 3],
                    stats[i, 4],
                    stats[i, 5])
    end
end


function getComparison(algorithms::Dict{String, String}, algName::String)

    outputTable = DataFrame()

    compTable = readcsv(algorithms[algName])


    i = 1
    for name = keys(algorithms)
        thetable = readcsv(algorithms[name]) 
        stats =  statitistic(thetable)

        outputTable[Symbol("$(name)_mean")] =  stats[ :, 3 ]
        # outputTable[Symbol("$(name)_std")]  =  stats[ :, 5 ]

        if name == algName
            continue
        end

        res = String[]

        for i = 1:size(compTable,1)
            x, y = compTable[i,:], thetable[i,:]

            p = pvalue(SignedRankTest(x, y)) 

            if p < 0.05
                mx, my = mean(x), mean(y)
                if mx < my
                    push!(res, "+")
                elseif mx == my
                    push!(res, "≈")
                else
                    push!(res, "-")
                end
            
            else
                push!(res, "≈")
            end
        end

        outputTable[Symbol("$(algName)_vs_$(name)")]  =  res
        
        i += 1

    end


    return outputTable    
end

function comparisonToLatex(algorithms::Dict{String, String}, algName::String)

    thetable = getComparison(algorithms, algName)

    print("fn & ")
    for n = names(thetable)
        print(string(n), " & ")
    end

    println("")

    for i = 1:size(thetable, 1)
        print(i, " & ")
        for j = 1:size(thetable, 2)
            d = thetable[i, j]

            if typeof(d) == String

                if d == "≈"
                    d = "\\approx"
                end

                print("\$$d\$")

                if j == size(thetable, 2)
                    println("\\\\ \\hline")
                else
                    print(" & ")
                end
                continue
            end

            @printf(" %.4e & ", d)
        end

    end
end

statitistic(fname::String; mapping::Function=identity) = statitistic( readcsv(fname); mapping=mapping )
printSummary(fname::String; mapping::Function=identity) = printSummary( statitistic(readcsv(fname)); mapping=mapping )
statsToLatex(fname::String; mapping::Function=identity) = statsToLatex(statitistic( readcsv(fname); mapping=mapping ))
printComparison(algorithms::Dict{String, String}, algName::String) = println(getComparison(D))


end # module
