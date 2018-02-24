export GameTree, GameNode, GameEdge
export play, move, reward, isfinal

mutable struct GameAction
    id::Int
    P::Float32
    stateid::Int
    N::Int
    Q::Float32
end

GameAction(id::Int, P::Float32) = GameAction(id, P, 0, 0, 0.0)

function backup!(a::GameAction, value::Float32)
    a.Q = (a.N * a.Q + value) / (a.N + 1)
    a.N += 1
end

mutable struct GameState
    data
    p
    v
    reward
    actions::Vector{GameAction}
end

GameState(data, p, v) = GameState(data, p, v, nothing, GameAction[])

isfinal(state::GameState) = isempty(state.actions)

function getpi(state::GameState)
    N = sum(a -> a.N, state.actions)
    @assert N > 0
    pi = zeros(state.p.data)
    for a in state.actions
        pi[a.id] = a.N / N
    end
    pi
end


mutable struct GameTree
    dict::Dict
    states::Vector{GameState}
    model
end

function GameTree(initdata::T, model) where T
    tree = GameTree(Dict{T,Int}(), GameState[], model)
    register!(tree, initdata)
    tree
end

function train(initdata, model)
    opt = SGD()
    for iter = 1:300
        println("iter: $iter")
        nplays = 200
        prog = Progress(nplays)
        states = GameState[]
        for i = 1:nplays
            path = play(initdata, model)
            append!(states, path)
            ProgressMeter.next!(prog)
        end
        opt.rate = 0.1 / length(states)

        p = concat(2, map(s -> s.p, states))
        pi = cat(2, map(s -> getpi(s), states)...)
        v = concat(2, map(s -> s.v, states))
        r = map(s -> Float32(s.reward), states)
        r = reshape(r, 1, length(r))
        l = softmax_crossentropy(Var(pi), p)
        l += mse(v, Var(r))

        loss = sum(l.data) / length(states)
        println("Loss:\t$loss")

        params = gradient!(l)
        foreach(opt, params)
    end

    println("play start")
    states = play(initdata, model)
    for s in states
        println(string(s.data))
        println(s.p.data)
        println(s.v.data)
        println()
    end
end

function play(initdata, model)
    tree = GameTree(initdata, model)
    states = GameState[]
    state = tree.states[1]
    while !isfinal(state)
        push!(states, state)
        for i = 1:50
            search!(tree, state)
        end
        state = move(tree, state)
    end

    r = -state.reward
    #@assert r == 1 || r == 0
    for i = length(states):-1:1
        states[i].reward = r
        r = -r
    end
    states
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
    length(state.actions) == 1 && return maxa
    maxU = typemin(Float64)
    N = sum(a -> a.N, state.actions)
    cpuct = 3
    for a in state.actions
        U = a.Q + cpuct * a.P * sqrt(N) / (a.N + 1)
        if U > maxU
            maxU = U
            maxa = a
        end
    end
    maxa
end

function register!(tree::GameTree, data)
    id = get!(tree.dict, data, length(tree.dict)+1)
    if id > length(tree.states)
        r = reward(data)
        if r <= -10.0
            actions = getactions(data)
            p, v = tree.model(data)
            state = GameState(data, p, v)
            Ps = softmax(p.data[actions])
            for i = 1:length(actions)
                P = Ps[i]
                push!(state.actions, GameAction(actions[i],P))
            end
        else
            actions = Int[]
            p = nothing
            v = Var(Float32[r])
            state = GameState(data, p, v)
        end
        state.reward = r
        push!(tree.states, state)
        @assert length(tree.states) == length(tree.dict)
    end
    id
end

function search!(tree::GameTree, initstate::GameState)
    state = initstate
    actions = GameAction[]
    while !isfinal(state)
        action = select(state)
        push!(actions, action)
        if action.stateid == 0
            data = move(state.data, action.id)
            action.stateid = register!(tree, data)
            state = tree.states[action.stateid]
            break
        else
            state = tree.states[action.stateid]
        end
    end

    v = state.v.data[1]
    for i = length(actions):-1:1
        backup!(actions[i], v)
        v = -v
    end
end
