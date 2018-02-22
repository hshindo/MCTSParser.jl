





mutable struct Action
    id::Int
    stateid::Int
    N::Float64
    P::Float64
    Q::Float64
end
Action(id) = Action(id, 0, 0.0, 0.0, 0.0)

function backup!(act::Action, value::Float64)
    act.Q = (act.N*act.Q + value) / act.N
    act.N += 1
end

mutable struct State
    data
    actions::Vector{Action}
    p
    v
end
State(data) = State(data, Action[], nothing, nothing)

isfinal(state::State) = isempty(state.actions)

struct DAG
    dict::Dict
    states::Vector{State}
end

function play(dag::DAG)
    stateids = Int[]
    state = dag.states[1]
    while !isfinal(state)
        for _ = 1:1600
            search(dag, 1)
        end
        state = move(state)
        push!(states, state)
    end
    states
end

function move(state::State)
    state
end

function search(dag::DAG, initstate::Int)
    state = initstate
    actions = Action[]
    while true
        st = dag.states[stateid]
        act = select(state)
        if act.stateid == 0
            data = move(state.data, act.id)
            state = State(data)
            stateid = get!(dag.dict, state, length(dag.dict)+1)
            act.stateid = stateid
            if stateid == length(dag.dict)
                for actid in nextactions(data)
                    push!(state.actions, Action(actid))
                end
                break
            end
        end
        state = dag.states[act.stateid]
    end
    for act in actions
        backup!(act, state.v)
    end
end

function select(state::State)
    N = sum(a -> a.N, state.actions)
    maxact = state.actions[1]
    maxU = typemin(Float64)
    for act in state.actions
        U = act.Q + a.P * sqrt(N) / (1.0 + act.N)
        if U > maxU
            maxU = U
            maxact = act
        end
    end
    maxact
end
