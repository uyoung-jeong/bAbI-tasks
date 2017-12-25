-- Copyright (c) 2015-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree. An additional grant
-- of patent rights can be found in the PATENTS file in the same directory.

local List = require 'pl.List'

local babi = require 'babi._env'
local stringify = require 'babi.stringify'

local Task = torch.class('babi.Task', babi)

--- Generate a story and questions, and print to screen.
function Task:generate(config)
    for i = 1, 200 do
        math.randomseed(i+os.time())
        local world = self:new_world(config)
        local story, knowledge = self:generate_story(world, babi.Knowledge(world),
                                             List(), config)
        str = stringify(story, knowledge, config)
        -- write to file
        if i % 100 == 0 then
            print(i)
        end
        file = io.open("q1_valid.txt", "a")
        file:write('\n')
        file:write(str)
    end
    return str
end

return Task
