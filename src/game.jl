struct Game
    state
    players::Tuple
end

Game(state, players...) = Game(state, players)

function play(game::Game)
    state = game.state
    count = 1
    while true
        for p in game.players
            println("player: $p")
            println(state)
            action = move(p, state)
            state = transition(state, action)
            r = reward(state)
            if r == nothing
            else
                println(state)
                println("reward: $r")
                println("finish.")
                return
            end
        end
    end
end

struct HumanPlayer
end

Base.print(io::IO, ::HumanPlayer) = print(io, "HumanPlayer")

function move(::HumanPlayer, state)
    while true
        print("Input next move: ")
        action = tryparse(Int, chomp(readline()))
        isnull(action) || return action.value
        println("Invalid move. Try again.")
    end
end

const WHITE = Int8(1)
const BLACK = Int8(2)
const BLANK = Int8(3)

struct TicTacToe
    player::Int
    board::Vector{Int8}
    count::Int
end
TicTacToe() = TicTacToe(WHITE, fill(BLANK,9), 0)

Base.isequal(x::TicTacToe, y::TicTacToe) = isequal(x.board, y.board)
Base.hash(x::TicTacToe) = hash(x.board)

function Base.print(io::IO, ttt::TicTacToe)
    s = map(ttt.board) do i
        i == WHITE && return "○"
        i == BLACK && return "×"
        i == BLANK && return "_"
        throw("")
    end
    p = ttt.player == WHITE ? "○" : "×"
    print(io, "player: $p\n$(s[1]) $(s[2]) $(s[3])\n$(s[4]) $(s[5]) $(s[6])\n$(s[7]) $(s[8]) $(s[9])")
end

function transition(ttt::TicTacToe, action::Int)
    @assert ttt.board[action] == BLANK
    board = copy(ttt.board)
    board[action] = ttt.player
    player = ttt.player == WHITE ? BLACK : WHITE
    TicTacToe(player, board, ttt.count+1)
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
            @assert ttt.board[p[1]] != ttt.player
            return -1.0
        end
    end
    ttt.count < 9 && return nothing
    0.0
end
