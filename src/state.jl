struct Action
    N::Int
    W::Float64
    Q::Float64
    P::Float64
end

mutable struct State
    actions::Vector{Action}
    children::Vector{State}
    parent
end

function move(st::State)
    maxi = 0
    maxN = 0.0
    for i = 1:length(st.actions)
        a = st.actions[i]
        if a.N > maxN
            maxN = a.N
            maxi = i
        end
    end
    st.children[maxi]
end

function simulate(st::State)
    leaf = select(st)
    p, v = model(leaf)
    backup!(st)
end

function select(st::State)
    while !isempty(st.children)
        maxscore = 0.0
        maxi = 0
        for i = 1:length
            a = st.actions[i]
            U = 5 * a.P
            score = a.Q + U
            if score > maxscore
                maxscore = score
                maxi = i
            end
        end
        st = st.children[maxi]
    end
    st
end

function backup!(st::State)
    while st.parent

        st = st.parent
    end
end
