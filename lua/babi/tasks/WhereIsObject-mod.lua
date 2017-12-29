-- Copyright (c) 2015-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree. An additional grant
-- of patent rights can be found in the PATENTS file in the same directory.

local tablex = require 'pl.tablex'

local babi = require 'babi'
local actions = require 'babi.actions'

local WhereIsObject = torch.class('babi.WhereIsObject', 'babi.Task', babi)

function WhereIsObject:new_world()
    local world = babi.World()
    world:load((BABI_HOME or '') .. 'tasks/worlds/world_basic_mod.txt')
    return world
end

function WhereIsObject:generate_story(world, knowledge, story)
    local num_questions = 0
    local story_length = 0

    local allowed_actions = {actions.get, actions.drop, actions.teleport}
    
    --state actors at initial stage
    local actors = world:get_actors(true, function(a, b) return a.name < b.name end)
    local subactors = {actors[1], actors[2], actors[3]}
    --[[ initialize with 4 contexts
    for i = 1,4 do
        local init_clause
        while not init_clause do
            if i==4 then -- teleport
                init_clause = babi.Clause.sample_valid(
                    world, {true}, subactors,
                    {actions.teleport}, world:get_locations()
                )
            else
                init_clause = babi.Clause.sample_valid_with_actor(
                        world, {true}, actors, i, 
                    {actions.get}, world:get_objects()
                )
            end
        end
        init_clause:perform()
        story:append(init_clause)
        knowledge:update(init_clause)
        story_length = story_length + 1
    end
    ]]
    -- initialize all 4 actors
    for i = 1,8 do
        local init_clause
        while not init_clause do
            if i%2==0 then -- teleport
                init_clause = babi.Clause.sample_valid_with_actor(
                    world, {true}, actors, math.floor(i/2 + 0.5),
                    {actions.teleport}, world:get_locations()
                )
            else
                init_clause = babi.Clause.sample_valid_with_actor(
                    world, {true}, actors, math.floor(i/2 + 0.5), 
                    {actions.get}, world:get_objects()
                )
            end
        end
        init_clause:perform()
        story:append(init_clause)
        knowledge:update(init_clause)
        story_length = story_length + 1
    end

    local isTeleport = 0 --flag that determines whether teleport occured
    local rand_actor = math.random(4)
    for i = 1, 37 do
        local known_objects = tablex.filter(
            knowledge:current():find('is_in'),
            function(entity)
                return entity.is_gettable and
                    knowledge:current()[entity.is_in]:get_value('is_in')
            end
        )
        if (i-1)%9 == 0 then 
            -- question
            if #known_objects < 1 then
                error('#known_objects < 1')
                return nil
            end
            local random_object =
                    known_objects[math.random(#known_objects)]
            local value, support =
                    knowledge:current()[random_object]:get_value('is_in', true)
            local _, holder_support =
                    knowledge:current()[random_object.is_in]:get_value('is_in',
                                                                       true)
            story:append(babi.Question(
                    'eval',
                    babi.Clause(world, true, world:god(), actions.set,
                        random_object, 'is_in', value.is_in),
                    support + holder_support
                ))

            story_length = 0
            num_questions = num_questions + 1
            isTeleport = 0
            rand_actor = math.random(4)
        else 
            -- create clause
            local clause
            if (((i+1)%9==0)and(#known_objects<1)) then  --force to make known_object
                while not clause do
                    clause = babi.Clause.sample_valid_with_actor(
                        world, {true}, world:get_actors(), rand_actor,
                        {actions.get}, world:get_objects()
                    )
                end
            end
            local rv = math.random(3) -- 1,2: get/drop, 3: teleport
            while not clause do
                if (rv == 3) or (i%9==0 or isTeleport==0) then
                    clause = babi.Clause.sample_valid_with_actor(
                        world, {true}, world:get_actors(), rand_actor,
                        {actions.teleport}, world:get_locations()
                    )
                else
                    clause = babi.Clause.sample_valid(
                        world, {true}, world:get_actors(),
                        {actions.get, actions.drop}, world:get_objects()
                    )
                end
            end
            if rv ==3 then 
                isTeleport = 1
            end
            clause:perform()
            story:append(clause)
            knowledge:update(clause)
            story_length = story_length + 1
        end
    end
    print('story generation ended')
    return story, knowledge
end

return WhereIsObject
