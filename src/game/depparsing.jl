struct DepParsingState
    words::Vector{Int}
    postags::Vector{Int}
    golds::Vector{Int}
    preds::Vector{Int}
    target::Int
end

function DepParsingState(words::Vector{Int}, postags::Vector{Int})
    @assert length(words) == length(postags)
    heads = zeros(Int, length(words))
    DepParsingState(words, postags, heads, 0)
end

function Base.isequal(x::DepParsingState, y::DepParsingState)
    isequal(x.target,y.target) && isequal(x.heads,y.heads)
end
Base.hash(x::DepParsingState) = hash(x.heads, hash(x.target))

function legalactions(state::DepParsingState)
    all(x -> x == 0, state.heads) && return Int[]

    actions = Int[]
    if state.target > 0
        for i = 1:length(state.heads)
            state.heads[i] == 0 && i != state.target && push!(actions,i)
        end
    else
        for i = 1:length(state.heads)
            state.heads[i] == 0 && push!(actions,i)
        end
    end
    actions
end

function reward(state::DepParsingState)
    c = 0
    for i = 1:length(golds)
        golds[i] == preds[i] && (c += 1)
    end
    c / length(golds)
end

function transition(state::DepParsingState, action::Int)
    heads = copy(state.heads)
    if state.target > 0
        @assert heads[state.target] == 0
        heads[state.target] = action
        target = 0
    else
        target = action
    end
    DepParsingState(state.words, state.postags, heads, target)
end
