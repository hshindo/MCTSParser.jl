export TicTacToe

const BLANK = Int8(3)

struct TicTacToe
    player::Int
    board::Vector{Int8}
    state::Int
end

TicTacToe() = TicTacToe(1, fill(BLANK,9), 100)

Base.isequal(x::TicTacToe, y::TicTacToe) = isequal(x.board, y.board)
Base.hash(x::TicTacToe) = hash(x.board)

function transition(ttt::TicTacToe, action::Int)
    @assert ttt.board[action] == BLANK
    player = ttt.player == 1 ? 2 : 1
    board = copy(ttt.board)
    board[action] = ttt.player
    state = getstate(player, board)
    TicTacToe(player, board, state)
end

function getstate(player::Int, board::Vector{Int8})
    pats = [(1,2,3), (4,5,6), (7,8,9), (1,4,7), (2,5,8), (3,6,9), (1,5,9), (3,5,7)]
    for p in pats
        board[p[1]] == BLANK && continue
        if board[p[1]] == board[p[2]] == board[p[3]]
            @assert player != board[p[1]]
            return -1
        end
    end
    c = count(x -> x == BLANK, board)
    c > 0 ? 100 : 0
end

function legalactions(ttt::TicTacToe)
    ttt.state == 100 || return Int[]
    actions = Int[]
    for i = 1:length(ttt.board)
        ttt.board[i] == BLANK && push!(actions,i)
    end
    actions
end

function reward(ttt::TicTacToe)
    # ttt is final
    @assert ttt.state != 100
    Float32(ttt.state)
end

function Base.print(io::IO, ttt::TicTacToe)
    s = map(ttt.board) do i
        i == 1 && return "○"
        i == 2 && return "×"
        i == BLANK && return "_"
        throw("")
    end
    print(io, "player: $(ttt.player)\n$(s[1]) $(s[2]) $(s[3])\n$(s[4]) $(s[5]) $(s[6])\n$(s[7]) $(s[8]) $(s[9])")
end

mutable struct NN
    g
end

function NN()
    T = Float32
    embeds = zerograd(Uniform(-0.001,0.001)(T,10,3))
    h = lookup(Node(embeds), Node(name="x"))
    h = Linear(T,90,50)(h)
    h = relu(h)
    p = Linear(T,50,9)(h)
    v = Linear(T,50,1)(h)
    v = tanh(v)
    NN(Graph(p,v))
end

function (nn::NN)(ttt::TicTacToe)
    if ttt.player == 1
        x = ttt.board
    else
        board = copy(ttt.board)
        for i = 1:length(board)
            board[i] == BLANK && continue
            board[i] = board[i] == 1 ? 2 : 1
        end
        x = board
    end
    nn.g(Var(x))
end
