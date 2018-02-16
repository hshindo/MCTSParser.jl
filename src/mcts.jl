struct TTTState
    player::Int
    board::Vector{Int}
end

TTTState(player::Int) = TTTState(player, fill(3,9))

function Base.string(st::TTTState)
    strs = map(st.board) do i
        i == 1 && return "○"
        i == 2 && return "×"
        i == 3 && return "_"
        throw("")
    end
    "$(strs[1:3])\n$(strs[4:6])\n$(strs[7:9])"
end

function reward(st::TTTState)
    @assert isend(st)
    pats = [(1,2,3), (4,5,6), (7,8,9), (1,4,7), (2,5,8), (3,6,9), (1,5,9), (3,5,7)]
    for p in pats
        if st.board[p[1]] == st.board[p[2]] == st.board[p[3]]
            return st.board[p[1]] == st.player ? 1 : -1
        end
    end
    0
end

isend(st::TTTState) = all(i -> i != 3, st.board)

function move(st::TTTState, act::Int)
    @assert st.boart[act] == 3
    board = copy(st.board)
    board[act] = st.player
    TTTState(st.player, board)
end


mutable struct NN
    g
end

function NN()
    T = Float32
    embeds = Normal(0,0.01)(T,10,3)
    h = lookup(Node(embeds), Node(name="x"))
    h = Linear(T,90,90)(h)
    h = tanh(h)
    h = Linear(T,90,10)(h)
    NN(Graph(h))
end

function (nn::NN)(st::TTTState)
    y = copy(nn.g(st).data)
    for i = 1:length(st.boards)
        st.board[i] == 3 || y[i] = 0.0
    end
    y[1:9], y[10]
end





struct Action
    N::Int
    W::Float64
    Q::Float64
    P::Float64
    stateid::Int
end


struct MCTS{T}
    statedict::Dict{T,Int}
    states::Vector{T}
    actions::Vector{Vector{Action}}
    nn
end

function MCTS(state, nn)
    statedict = Dict(state => 1)
    MCTS(statedict, [state], Vector{Action}[], nn)
end

hasstate(mcts::MCTS, state) = haskey(mcts.dict, state)

function train(mcts::MCTS)
    for epoch = 1:1000
        for i = 1:100
            play(mcts)
        end
        train!(nn, samples)
    end
end

function play(mcts::MCTS)
    st = mcts.states[1]
    while !isend(st)
        for i = 1:1000
            expand(mcts, st)
        end
        st = move(st)
    end
end

function expand(mcts::MCTS, stateid::Int)
    st = mcts.states[stateid]
    actions = mcts.actions[stateid]
    N = sum(a -> a.N, actions)
    maxu = typemin(Float64)
    maxi = 0
    for i = 1:length(actions)
        u = a.Q + 1.0 * a.P * sqrt(N) / (1.0+a.N)
        if maxu < u
            maxu = u
            maaxi = i
        end
    end


    isend(st) && return reward(st)
    id = get!(mcts.statedict, st, length(mcts.statedict)+1)
    if haskey(mcts, st)

        for a in mcts.nodes[id].actions
            u = a.Q + 1.0 * a.P * sqrt(sum(a.N)) / (1.0+a.N)
            if u > maxu
                maxu = u
                besta = a
            end
        end

    else
        mct.dict[st] = st
        p, v = evaluate(st)
    end
end

function move(mcts::MCTS, i::Int)
    node = mcts.nodes[i]
    probs = map(a -> a.pi, node.actions)
    index = sample(probs)
    move(st, i)
end

function sample(probs::Vector{Float64})
    r = rand(1)[1] * sum(probs)
    sum = 0.0
    for i = 1:length(probs)
        p = probs[i]
        sum += p
        r >= sum && return i
    end
    length(probs)
end
