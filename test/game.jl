using MCTSParser
using JLD2, FileIO

if false
    tree = GameTree(TicTacToe(), MCTSParser.NN())
    train(tree, 300, 200, 100)
    save("tree.jld2", "tree", tree)
else
    tree = load("tree.jld2", "tree")
    nodes = selfplay(tree, 100)
    for node in nodes
        println(node.state)
        println(node.p.data)
        println(node.v.data)
    end
    println("finish")
end
