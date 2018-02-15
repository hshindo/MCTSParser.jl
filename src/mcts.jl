struct TTTState
    board::Vector{Int}
end

function Base.string(st::TTTState)
    strs = map(st.board) do i
        i == 1 && return "_"
        i == 2 && return "○"
        i == 3 && return "×"
        throw("")
    end
    "$(strs[1:3])\n$(strs[4:6])\n$(strs[7:9])"
end

function reward(st::TTTState)
    pats = [(1,2,3), (4,5,6), (7,8,9), (1,4,7), (2,5,8), (3,6,9), (1,5,9), (3,5,7)]
    for p in pats
        st.board[p[1]] == st.board[p[2]] == st.board[p[3]] && return 1
    end
    0
end

isend(st::TTTState) = all(i -> i != 1, st.board)
move(st::State, act::Int) = State()
evaluate(st::State, nn)

mutable struct NN
end

function (nn::NN)(st::State)
end

struct Action
    N::Int
    W::Float64
    Q::Float64
    P::Float64
    stateid::Int
end

struct MCTSNode
    value::Float64
    actions::Vector{Action}
end

function MCTSNode(stateid::Int)
end

struct MCTS
    dict::Dict
    nodes::Vector{MCTSNode}
    nn
end

function MCTS(initstate, nn)
    dict = Dict()
    nodes = Node[]
    MCTS(dict, nodes, nn)
end

function train(mcts::MCTS)
    for epoch = 1:1000
        for i = 1:100
            play(mcts)
        end
        nn2 = train(nn, samples)
    end
end

function play(mcts::MCTS)
    st = mcts.states[1]
    for i = 1:1000
        expand(mcts, st)
    end
    st = move(st)
end

function expand(mcts::MCTS, st)
    isend(st) && return reward(st)
    if isvisit(st)

    else
        mct.dict[st] = st
        p, v = evaluate(st)

    end
end
