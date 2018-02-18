mutable struct Edge
    P::Float64
    N::Float64
    Q::Float64
    nextid::Int
end

struct Node
    p
    v
    z::Float64
    Ps
    Ns
    Qs
end

function isfinal(node::Node)
    if isinf(node.z)
        node.z = reward(node.st)
    end
end

struct MCT
    dict::Dict
end

function train(mct::MCT)
end

function play(mct::MCT)
    id = 1
    ids = Int[]
    while true
        for i = 1:1600
            expand(mct, id)
        end
        id = sample(mct, id)
        isend(node) && break
    end
    z = node.z

end

function expand(mct::MCT, id::Int)
    st = mct.states[id]
    node = mct.nodes[id]
    if firstvisit(node)
        actions = actions(st)
        if isempty(actions)
        else

        end
    else
        if isfinal(node)
        else
            
        end
    end

    if isempty(node.edges)
        if node.z == inf
            node.z = reward(st)
        else
            node.p, node.v = mct.nn(st)
            for a in actions(st)
                st = move(st, act)
                stateid = get!(mct.dict, st, length(mct.dict)+1)
                if stateid == length(mct.dict)
                    z = getz(st)
                    Node(st, z)
                    act = Action(p[a], 0.0, 0.0, stateid)
                else
                end
                push!(actions, act)
            end
        end
    else
        besta
        node = mct.nodes[besta.nextid]
    end
end
