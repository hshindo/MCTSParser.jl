const BLANK = Int8(3)

mutable struct TicTacToe
    player::Int
    board::Vector{Int8}
end
TicTacToe(player::Int) = TicTacToe(player, fill!(BLANK,9))

function Base.string(ttt::TicTacToe)
    strs = map(ttt.board) do i
        i == 1 && return "○"
        i == 2 && return "×"
        i == BLANK && return "_"
        throw("")
    end
    "$(strs[1:3])\n$(strs[4:6])\n$(strs[7:9])"
end

function reward(ttt::TicTacToe)
    pats = [(1,2,3), (4,5,6), (7,8,9), (1,4,7), (2,5,8), (3,6,9), (1,5,9), (3,5,7)]
    for p in pats
        if ttt.board[p[1]] == ttt.board[p[2]] == ttt.board[p[3]]
            return ttt.board[p[1]] == ttt.player ? 1 : -1
        end
    end
    0
end

function isfinal(ttt::TicTacToe)

end


function move(tttt::TicTacToe, act::Int)
    @assert ttt.boart[act] == BLANK
    board = copy(ttt.board)
    board[act] = ttt.player
    TicTacToe(ttt.player, board)
end

function NN()
    T = Float32
    embeds = randn(T)
    h = lookup(Node(name="x"))
    h = Linear(T,50,10)(h)
    embeds = Normal(0,0.01)(T,10,3)
    h = lookup(Node(embeds), Node(name="x"))
    h = Linear(T,90,90)(h)
    h = tanh(h)
    h = Linear(T,90,10)(h)
    NN(Graph(h))
end





mutable struct Action
    id::Int
    stateid::Int
    N::Float64
    P::Float64
    Q::Float64
end
Action(id) = Action(id, 0, 0.0, 0.0, 0.0)

function backup!(act::Action, value::Float64)
    act.Q = (act.N*act.Q + value) / act.N
    act.N += 1
end

mutable struct State
    data
    actions::Vector{Action}
    p
    v
end
State(data) = State(data, Action[], nothing, nothing)

isfinal(state::State) = isempty(state.actions)

struct DAG
    dict::Dict
    states::Vector{State}
end

function play(dag::DAG)
    stateids = Int[]
    state = dag.states[1]
    while !isfinal(state)
        for _ = 1:1600
            search(dag, 1)
        end
        state = move(state)
        push!(states, state)
    end
    states
end

function move(state::State)
    state
end

function search(dag::DAG, initstate::Int)
    state = initstate
    actions = Action[]
    while true
        st = dag.states[stateid]
        act = select(state)
        if act.stateid == 0
            data = move(state.data, act.id)
            state = State(data)
            stateid = get!(dag.dict, state, length(dag.dict)+1)
            act.stateid = stateid
            if stateid == length(dag.dict)
                for actid in nextactions(data)
                    push!(state.actions, Action(actid))
                end
                break
            end
        end
        state = dag.states[act.stateid]
    end
    for act in actions
        backup!(act, state.v)
    end
end

function select(state::State)
    N = sum(a -> a.N, state.actions)
    maxact = state.actions[1]
    maxU = typemin(Float64)
    for act in state.actions
        U = act.Q + a.P * sqrt(N) / (1.0 + act.N)
        if U > maxU
            maxU = U
            maxact = act
        end
    end
    maxact
end
