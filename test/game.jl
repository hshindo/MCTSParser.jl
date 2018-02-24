include(joinpath(@__DIR__,"../src/game.jl"))

game = Game(TicTacToe(), HumanPlayer(), HumanPlayer())
play(game)
