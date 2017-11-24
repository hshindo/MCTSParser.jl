struct NN

end

function NN(wordembeds::Var)
    T = Float32
    w = Node()
    h = lookup(wordembeds, w)
    dh = 300
    h = Conv1D(T,5,100,dh,2,1)(h)
    h = relu(h)

    istrain = Node()
    for i = 1:2
        h = dropout(h, 0.3, istrain)
        h = Conv1D(T,5,dh,dh,2,1)(h)
        h = relu(h)
    end
    h = Linear(T,dh,ntags)(h)
    g = Graph(input=(w1,w2,c,istrain), output=h)
    NN(g)
end
