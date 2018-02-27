export HumanPlayer, MCTSPlayer

struct HumanPlayer
end

Base.print(io::IO, ::HumanPlayer) = print(io, "HumanPlayer")

function nextmove(::HumanPlayer, state)
    while true
        print("Input next move: ")
        action = tryparse(Int, chomp(readline()))
        isnull(action) || return action.value
        println("Invalid move. Try again.")
    end
    transition()
end
