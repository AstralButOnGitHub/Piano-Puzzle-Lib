---@class PianoJumpArea : Event
---@overload fun(...) : PianoJumpArea
local PianoJumpArea, super = Class(Event)

function PianoJumpArea:init(data)
    super.init(self, data)
    self.properties = data.properties or {}

    self.solid = false
    self.visible = false
end

function PianoJumpArea:update()
    for _, object in ipairs(Game.world.map:getEvents()) do
        if object:includes(MovingObject) and self:meetsObject(object) and object.jump ~= nil then
            object:jump()
        end
    end
end

return PianoJumpArea