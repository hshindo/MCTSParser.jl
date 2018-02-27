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
            action = nextaction_play(p, state)
            state = transition(state, action)
            actions = getactions(state)
            if isempty(actions)
                r = reward(state)
                println(state)
                println("reward: $r")
                println("finish.")
                return
            end
        end
    end
end
