---@class PianoSpeedZone : Event
---@overload fun(...) : PianoSpeedZone
local PianoSpeedZone, super = Class(Event)

function PianoSpeedZone:init(data)
    super.init(self, data)
    self.properties = data.properties or {}

    self.solid = false
    self.visible = false
    self.max_speed = self.properties["max_speed"] or nil
end

function PianoSpeedZone:update()
    for _, object in ipairs(Game.world.map:getEvents()) do
        if object:includes(MovingObject) and self:meetsObject(object) and object.jump ~= nil and self.max_speed ~= nil then
            object.max_speed = self.max_speed
        end
    end
end

return PianoSpeedZone