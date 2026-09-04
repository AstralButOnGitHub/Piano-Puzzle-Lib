---@class MusicGate : Event
---@overload fun(...) : MusicGate
local MusicGate, super = Class(Event)

function MusicGate:init(data)
    super.init(self, data)
    self.properties = data.properties or {}
    if self.properties["flip"] == true then
        self.scale_x = -self.scale_x
    end
    self.piano = Game.world:getEvent(self.properties["piano"]) or nil
    self:setSprite("world/events/music_gate")
    self.x = self.x - (self.width / 2)
    self.y = self.y - self.height
    self.solid = true

    self.fading = false
end

function MusicGate:onLoad()
    if self.piano ~= nil and self.piano:getFlag("hassolved", false) == true then
        self:remove()
    end
end

function MusicGate:unlock()
    self.fading = true
end

function MusicGate:update()
    if self.fading then
        local amount = (DTMULT * 2)
        self.y = self.y - amount * 2
        self.alpha = self.alpha - (amount / 30)
        if self.alpha <= 0 then
            self:remove()
        end
    else
        if self.piano ~= nil and self.piano.cutscene == nil and self.piano:getFlag("hassolved", false) == true then
            self:unlock()
        end
    end
end

function MusicGate:draw()
    love.graphics.setColor(1, 1, 1, self.alpha)
    love.graphics.draw(self.sprite.texture, 0, 0, 0, 2, 2)
    if DEBUG_RENDER then
        self:drawDebug()
    end
end

return MusicGate