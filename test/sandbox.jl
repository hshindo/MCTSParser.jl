workspace()
using MCTSParser

ttt = TicTacToe(1)
game = GameTree(ttt)


ttt = move(ttt, 1)
ttt = move(ttt,9)
reward(ttt)
ttt.player
string(ttt) |> println
