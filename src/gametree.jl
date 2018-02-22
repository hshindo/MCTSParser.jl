export GameTree, GameNode, GameEdge
export move, reward, isfinal

mutable struct GameAction
    id::Int
    stateid::Int
    N::Float64
    Q::Float64
end

Action(id::Int) = GameEdge(action, 0, 0.0, 0.0)

function backup!(a::GameAction, value::Float64)
    a.Q = (a.N * a.Q + value) / (a.N + 1.0)
    a.N += 1.0
end

mutable struct GameState{T}
    data::T
    p
    v
    N::Float64
    actions::Vector{GameAction}
end

GameState(data, p, v) = GameState(data, p, v, 0.0, GameAction[])

isfinal(state::GameState) = isempty(state.actions)


mutable struct GameTree{T}
    dict::Dict{T,Int}
    states::Vector{GameState}
    model
end

function GameTree(initdata::T, model) where T
    dict = Dict(initdata => 1)
    p, v = model(data)
    initstate = GameState(initdata, p, v)
    GameTree(dict, [initstate], model)
end

function play(tree::GameTree)
    state = tree.states[1]
    while !isfinal(state)
        for _ = 1:100
            search!(tree, state)
        end
        state = move(state)
    end
end

function move(tree::GameTree, state::GameState)
    maxa = state.actions[1]
    for a in state.actions
        if a.N > maxa.N
            maxa = a
        end
    end
    tree.states[maxa.stateid]
end

function select(state::GameState)
    maxa = state.actions[1]
    maxU = typemin(Float64)
    for a in state.actions
        U = a.Q + state.p.data[a.id] * sqrt(state.N) / (a.N + 1.0)
        if U > maxU
            maxU = U
            maxa = a
        end
    end
    maxa
end

function expand!(tree::GameTree, state::GameState, action::GameAction)
    data = move(state.data, action.id)
    stateid = get!(tree.dict, data, length(tree.dict)+1)
    action.stateid = stateid
    if stateid == length(tree.dict)
        p, v = tree.model(data)
        state = GameState(data, p, v)
        for a in getactions(data)
            push!(state.actions, GameAction(a,0.1))
        end
        state
    else
        tree.states[stateid]
    end
end

function search!(tree::GameTree, state::GameState)
    actions = GameAction[]
    while true
        action = select(state)
        push!(actions, action)
        if action.stateid == 0
            state = expand!(tree, state, action)
            break
        else
            state = tree.states[action.stateid]
        end
    end
    for a in actions
        tree.states[a.stateid].N += 1.0
        backup!(a, state.v)
    end
end
