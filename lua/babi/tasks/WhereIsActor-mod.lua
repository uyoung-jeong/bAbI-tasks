-- Copyright (c) 2015-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree. An additional grant
-- of patent rights can be found in the PATENTS file in the same directory.

local tablex = require 'pl.tablex'

local babi = require 'babi'

local actions = require 'babi.actions'

local function round(num)
    return math.floor(num + 0.5)
end

local function custom_rand(num)
    local r = math.random(num*20)
    local p1 = round(num*2)
    local p2 = round(num*6)
    local p3 = round(num*12)
    if r <=p1 then
	return 4
    elseif r <=p2 then
	return 3
    elseif r <=p3 then
	return 2
    else
	return 1
    end
end

g_a = 0
g_b = 0
g_c = 0
g_d = 0


local WhereIsActor = torch.class('babi.WhereIsActor', 'babi.Task', babi)

function WhereIsActor:new_world()
    local world = babi.World()
    world:load((BABI_HOME or '') .. 'tasks/worlds/world_basic.txt')
    return world
end

function WhereIsActor:generate_story(world, knowledge, story)
    -- Find the actors and the locations in the world
    local actors = world:get_actors(true, function(a, b) return a.name < b.name end)
    local locations = world:get_locations()

    -- shuffle to show in random order in 1-4
    numbers = {1, 2, 3, 4}
    for i = 1, 10 do
        local random1 = math.random(4)
        local random2 = math.random(4)
        numbers[random1], numbers[random2] = numbers[random2], numbers[random1]
    end

    -- Our story will be 4 statements, 1 question, 5 times
    for i = 1, 25 do
        if i <=4 then
            -- State all actors
            local clause = babi.Clause.sample_valid_with_actor(world, {true}, actors, numbers[i],
                {actions.teleport}, locations)
            clause:perform()
            story[i] = clause
            knowledge:update(clause)
        elseif i % 5 ~= 0 then
            -- Find a random action
            local clause = babi.Clause.sample_valid(world, {true}, actors,
                {actions.teleport}, locations)
            clause:perform()
            story[i] = clause
            knowledge:update(clause)
        else
            -- Find the actors of which we know the location
            local known_actors = tablex.filter(
                knowledge:current():find('is_in'),
                function(entity) return entity.is_actor end
            )
            table.sort(known_actors, function(a, b) return a.name < b.name end)

            -- Pick a random one and ask where he/she is
            -- local random_actor = known_actors[math.random(#known_actors)]
            local random_actor = known_actors[custom_rand(#known_actors)]
            local value, support =
                knowledge:current()[random_actor]:get_value('is_in', true)
            story[i] = babi.Question(
                'eval',
                babi.Clause(world, true, world:god(), actions.set,
                    random_actor, 'is_in', value),
                support
            )
            -- check frequency
            if string.sub(random_actor.name, 1, 1) == 'A' then
                g_a = g_a + 1
            elseif string.sub(random_actor.name, 1, 1) == 'B' then
                g_b = g_b + 1
            elseif string.sub(random_actor.name, 1, 1) == 'C' then
                g_c = g_c + 1
            else
                g_d = g_d + 1
            end
        end
    end
    file = io.open("freq.txt", "w")
    file:write("a:", g_a, "\n")
    file:write("b:", g_b, "\n")
    file:write("c:", g_c, "\n")
    file:write("d:", g_d, "\n")
    return story, knowledge
end

return WhereIsActor
