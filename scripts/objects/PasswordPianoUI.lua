---@class RemotePianoUI : Object
---@overload fun(...) : RemotePianoUI
local PasswordPianoUI, super = Class(Object)

function PasswordPianoUI:init(piano)
    super.init(self)
    self.drawpos = 0
    self.drawpostarget = 1
    self.piano = piano

    self.exitlength = 0
    self.resetlength = 0
end

function PasswordPianoUI:update()
    self.drawpos = MathUtils.approach(self.drawpos, self.drawpostarget, DTMULT / 15)
    if self.drawpos < 0 then
        self.piano.ui = nil
        self:remove()
    end
end

function PasswordPianoUI:draw()
    local function uitext(text, xof, yof, direction, fade, red)
        local text = love.graphics.newText(Assets.getFont("main"), text)

        local x = SCREEN_WIDTH - text:getWidth() - xof
        local y = SCREEN_HEIGHT - text:getHeight() - yof
        local diroffsets = {
            ["right"] = {1, 0},
            ["left"] = {-1, 0},
            ["up"] = {0, -1},
            ["down"] = {0, 1}
        }
        x = x + (diroffsets[direction][1] * 260) / (self.drawpos * 260)
        y = y + (diroffsets[direction][2] * 40) / (self.drawpos * 40)

        love.graphics.setColor(0, 0, 0, 1)
        for ox = -1, 1 do
            for oy = -1, 1 do
                love.graphics.draw(text, x + ox, y + oy)
            end
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(text, x, y)
        if fade ~= nil then
            love.graphics.setColor(1, 1, 1, fade)
            if red then
                love.graphics.setColor(1, 1 - fade, 1 - fade, fade)
            end
            love.graphics.draw(Assets.getTexture("ui/quiz_hud_timer_"..MathUtils.round((1 - fade) * 28)), x - 37, y + 3, 0, 2, 2)
        end
    end
    uitext("[Z] : Play", 21, 44, "right")
    uitext("Hold [X] : Exit", 21, 16, "right", self.exitlength, true)
end

return PasswordPianoUI