export Parser

mutable struct Parser
    worddict::Dict
end

function Parser()
    embedspath = joinpath(@__DIR__, "../.data/word2vec.NYT.100d.h5")
    words = h5read(embedspath, "words")
    worddict = Dict(words[i] => i for i=1:length(words))
    wordembeds = Var(h5read(embedspath,"vectors"))

    trainpath = joinpath(@__DIR__, "../.data/wsj_02-21.conll")
    testpath = joinpath(@__DIR__, "../.data/wsj_23.conll")
    traindata = readdata(trainpath, worddict)
    testdata = readdata(testpath, worddict)
    nn = NN(wordembeds)

    info("#Training examples:\t$(length(traindata))")
    info("#Testing examples:\t$(length(testdata))")
    info("#Words1:\t$(length(worddict1))")
    info("#Words2:\t$(length(worddict2))")
    info("#Chars:\t$(length(chardict))")
    info("#Tags:\t$(length(tagdict))")
    testdata = batch(testdata, 100)

    opt = SGD()
    for epoch = 1:nepochs
        println("Epoch:\t$epoch")
        opt.rate = learnrate * batchsize / sqrt(batchsize) / (1 + 0.05*(epoch-1))
        println("Learning rate: $(opt.rate)")

        shuffle!(traindata)
        batches = batch(traindata, batchsize)
        prog = Progress(length(batches))
        loss = 0.0
        for i in 1:length(batches)
            y = nn(batches[i]...)
            loss += sum(y.data)
            params = gradient!(y)
            foreach(opt, params)
            ProgressMeter.next!(prog)
        end
        loss /= length(batches)
        println("Loss:\t$loss")

        # test
        println("Testing...")
        preds = Int[]
        golds = Int[]
        for (w1,w2,c,t) in testdata
            y = nn(w1, w2, c)
            append!(preds, y)
            append!(golds, t.data)
        end
        length(preds) == length(golds) || throw("Length mismatch: $(length(preds)), $(length(golds))")

        preds = BIOES.decode(preds, tagdict)
        golds = BIOES.decode(golds, tagdict)
        fscore(golds, preds)
        println()
    end
    Decoder(worddict1, worddict2, chardict, tagdict, nn)
end

function readdata(path::String, worddict::Dict)
    data = Tuple[]
    unkword = worddict["UNKNOWN"]
    words = String[]
    heads = Int[]

    lines = open(readlines, path)
    push!(lines, "")
    for i = 1:length(lines)
        line = lines[i]
        if isempty(line)
            isempty(words) && continue
            wordids = Int[]
            for w in words
                w0 = replace(lowercase(w), r"[0-9]", '0')
                id = get(worddict, w0, unkword)
                push!(wordids, id)
            end
            w = Var(wordids)
            if isempty(heads)
                push!(data, (w,))
            else
                h = Var(heads)
                push!(data, (w,h))
            end
            empty!(words)
            empty!(heads)
        else
            items = Vector{String}(split(line,"\t"))
            word = strip(items[2])
            @assert !isempty(word)
            push!(words, word)
            head = parse(Int, items[7])
            push!(heads, head)
        end
    end
    Array{typeof(data[1])}(data)
end
