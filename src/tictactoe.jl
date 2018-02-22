export TicTacToe

const BLACK = Int8(1)
const WHITE = Int8(2)
const BLANK = Int8(3)

mutable struct TicTacToe
    player::Int
    board::Vector{Int8}
end
TicTacToe(player::Int) = TicTacToe(player, fill(BLANK,9))

function Base.string(ttt::TicTacToe)
    s = map(ttt.board) do i
        i == 1 && return "○"
        i == 2 && return "×"
        i == BLANK && return "_"
        throw("")
    end
    "$(s[1]) $(s[2]) $(s[3])\n$(s[4]) $(s[5]) $(s[6])\n$(s[7]) $(s[8]) $(s[9])"
end

function getactions(ttt::TicTacToe)
    actions = Int[]
    for i = 1:length(ttt.board)
        ttt.board[i] == BLANK && push!(actions,i)
    end
    actions
end

function reward(ttt::TicTacToe)
    pats = [(1,2,3), (4,5,6), (7,8,9), (1,4,7), (2,5,8), (3,6,9), (1,5,9), (3,5,7)]
    for p in pats
        ttt.board[p[1]] == BLANK && continue
        if ttt.board[p[1]] == ttt.board[p[2]] == ttt.board[p[3]]
            return ttt.board[p[1]] == ttt.player ? 1 : -1
        end
    end
    0
end

function move(ttt::TicTacToe, act::Int)
    @assert ttt.board[act] == BLANK
    board = copy(ttt.board)
    board[act] = ttt.player
    p = ttt.player == WHITE ? BLACK : WHITE
    TicTacToe(p, board)
end


mutable struct NN
    g
end

function NN()
    T = Float32
    embeds = Uniform(-0.001,0.001)(T,10,3)
    h = lookup(Node(name="x"))
    h = Linear(T,50,10)(h)
    embeds = Normal(0,0.01)(T,10,3)
    h = lookup(Node(embeds), Node(name="x"))
    h = Linear(T,90,90)(h)
    h = relu(h)
    p = Linear(T,90,9)(h)
    v = Linear(T,90,1)(h)
    v = tanh(v)
    NN(Graph(p,v))
end

function (nn::NN)(ttt::TicTacToe)
    x = ttt.board
    nn.g(Var(x))
end
