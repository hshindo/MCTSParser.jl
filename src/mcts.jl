export GameTree, GameNode, GameAction
export train, selfplay, transition

mutable struct GameAction
    id::Int
    P::Float32
    nodeid::Int
    N::Int
    Q::Float32
end

function GameAction(id::Int, P::Float32)
    GameAction(id, P, 0, 0, Float32(0))
end

function update!(act::GameAction, value::Float32)
    act.Q = (act.N * act.Q + value) / (act.N + 1)
    act.N += 1
end


mutable struct GameNode
    state
    p
    v
    r::Float32
    actions::Vector{GameAction}
end

isfinal(node::GameNode) = isempty(node.actions)

function nextaction_search(node::GameNode)
    @assert !isempty(node.actions)
    length(node.actions) == 1 && return node.actions[1]
    sqrtN = sqrt(sum(a -> a.N, node.actions))
    cpuct = 1
    maxact, maxU = node.actions[1], typemin(Float32)

    for act in node.actions
        U = act.Q + cpuct * act.P * sqrtN / (act.N+1)
        if U > maxU
            maxU = U
            maxact = act
        end
    end
    maxact
end

function nextaction_play(node::GameNode, tau::Int)
    @assert !isempty(node.actions)
    length(node.actions) == 1 && return node.actions[1]

    if tau == 0
        maxact = node.actions[1]
        for act in node.actions
            if act.N > maxact.N
                maxact = act
            end
        end
        maxact
    elseif tau == 1
        N = sum(a -> a.N, node.actions)
        r = N * rand()
        total = 0
        for act in node.actions
            total += act.N
            total > r && return act
        end
        node.actions[end]
    else
        throw("Invalid tau: $tau")
    end
end

function getpi(node::GameNode)
    N = sum(a -> a.N, node.actions)
    @assert N > 0
    pi = zeros(node.p.data)
    for a in node.actions
        pi[a.id] = a.N / N
    end
    pi
end



mutable struct GameTree{T}
    state2id::Dict{T,Int}
    nodes::Vector{GameNode}
    model
end

function GameTree(initstate::T, model) where T
    tree = GameTree(Dict{T,Int}(), GameNode[], model)
    get!(tree, initstate)
    tree
end

function Base.get!(tree::GameTree{T}, state::T) where T
    id = get!(tree.state2id, state, length(tree.state2id)+1)
    if id > length(tree.nodes)
        p, v = tree.model(state)
        actids = legalactions(state)
        if isempty(actids) # final state
            r = reward(state)
            actions = Int[]
        else
            actdict = Dict(x => x for x in actids)
            for i = 1:length(p.data)
                haskey(actdict,i) || (p.data[i] = -1024)
            end

            P = softmax(p.data[actids])
            r = typemin(Float32)
            actions = Array{GameAction}(length(actids))
            for i = 1:length(actids)
                actions[i] = GameAction(actids[i], P[i])
            end
        end
        node = GameNode(state, p, v, r, actions)
        push!(tree.nodes, node)
        @assert length(tree.nodes) == length(tree.state2id)
    end
    id
end

function train(tree::GameTree, niters::Int, nplays::Int, nsearches::Int)
    opt = SGD()
    for iter = 1:niters
        println("iter: $iter")
        samples = GameNode[]
        prog = Progress(nplays)
        for i = 1:nplays
            nodes = selfplay(tree, nsearches)
            append!(samples, nodes)
            ProgressMeter.next!(prog)
        end
        opt.rate = 0.01 / length(samples) * sqrt(length(samples))

        p = concat(2, map(s -> s.p, samples))
        pi = cat(2, map(s -> getpi(s), samples)...)
        v = concat(2, map(s -> s.v, samples))
        r = map(s -> s.r, samples)
        r = reshape(r, 1, length(r))
        l = softmax_crossentropy(Var(pi), p)
        l += mse(v, Var(r))

        loss = sum(l.data) / length(samples)
        println("Loss:\t$loss")

        params = gradient!(l)
        foreach(opt, params)
    end
end

function selfplay(tree::GameTree, nsearches::Int)
    initstate = tree.nodes[1].state
    tree = GameTree(initstate, tree.model)
    node = tree.nodes[1]
    nodes = GameNode[]

    count = 1
    while !isfinal(node)
        push!(nodes, node)
        for _ = 1:nsearches
            search!(tree, node)
        end
        tau = count <= 3 ? 1 : 0
        # tau = 0
        act = nextaction_play(node, tau)
        node = tree.nodes[act.nodeid]
        count += 1
    end

    finalnode = node
    r = -finalnode.r
    for i = length(nodes):-1:1
        nodes[i].r = r
        r = -r
    end
    # push!(nodes, finalnode)
    nodes
end

function search!(tree::GameTree, rootnode::GameNode)
    node = rootnode
    actions = []
    while !isfinal(node)
        act = nextaction_search(node)
        push!(actions, act)
        if act.nodeid == 0
            state = transition(node.state, act.id)
            nodeid = get!(tree, state)
            act.nodeid = nodeid
            node = tree.nodes[nodeid]
            break
        else
            node = tree.nodes[act.nodeid]
        end
    end

    #value = isfinal(node) ? node.r : node.v.data[1]
    #for act in actions
    #    update!(act, value)
    #end
    v = isfinal(node) ? node.r : node.v.data[1]
    for i = length(actions):-1:1
        update!(actions[i], v)
        v = -v
    end
end
