---@class PianoExit : Event
---@overload fun(...) : PianoExit
local PianoExit, super = Class(Event)

function PianoExit:init(data)
    super.init(self, data)
    self.properties = data.properties or {}
end

function PianoExit:update()
    for _, object in ipairs(Game.world.map:getEvents()) do
        if object:includes(MovingPiano) and self:meetsObject(object) then
            object:explode()

            -- local player = object.player
            -- local characters = object.characters

            -- player:setParent(Game.world)
            -- player:setPosition(object.x + 40, object.y + 40)
        end
    end
end

return PianoExit