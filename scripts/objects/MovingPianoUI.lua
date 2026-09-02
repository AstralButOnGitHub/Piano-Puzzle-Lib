---@class RemotePianoUI : Object
---@overload fun(...) : RemotePianoUI
local MovingPianoUI, super = Class(Object)

function MovingPianoUI:init(piano)
    super.init(self)
    self.drawpos = 0
    self.drawpostarget = 1
    self.piano = piano

    self.exitlength = 0
    self.resetlength = 0
end

function MovingPianoUI:update()
    self.drawpos = MathUtils.approach(self.drawpos, self.drawpostarget, DTMULT / 15)
    if self.drawpos < 0 then
        self.piano.ui = nil
        self:remove()
    end
end

function MovingPianoUI:draw()
        local diroffsets = {
            ["right"] = {1, 0},
            ["left"] = {-1, 0},
            ["up"] = {0, -1},
            ["down"] = {0, 1}
        }
    local function uitext(text, xof, yof, direction, fade, red, forcenoclock)
        local text = love.graphics.newText(Assets.getFont("main"), text)

        local x = SCREEN_WIDTH - text:getWidth() - xof
        local y = SCREEN_HEIGHT - text:getHeight() - yof

        x = x + (diroffsets[direction][1] * 260) / (self.drawpos * 260)
        y = y + (diroffsets[direction][2] * 40) / (self.drawpos * 40)

        love.graphics.setColor(0, 0, 0, 1)
        for ox = -1, 1 do
            for oy = -1, 1 do
                love.graphics.draw(text, x + ox, y + oy)
            end
        end
        love.graphics.setColor(1, 1, 1, 1)
        if red then
            love.graphics.setColor(1, 1 - fade, 1 - fade, 1)
        end
        love.graphics.draw(text, x, y)
        if fade ~= nil and not forcenoclock == true then
            love.graphics.setColor(1, 1, 1, fade)
            if red then
                love.graphics.setColor(1, 1 - fade, 1 - fade, fade)
            end
            love.graphics.draw(Assets.getTexture("ui/quiz_hud_timer_"..MathUtils.round((1 - fade) * 28)), x - 37, y + 3, 0, 2, 2)
        end
    end
    if self.piano.fakeout and not self.piano.faked then
        if Input.usingGamepad() then
            uitext(": Play Piano", 21, 72, "right")
            uitext("Hold", 139, 44, "right")
            uitext(": Reset", 21, 44, "right", self.resetlength, false, false, -89)

            if self.piano.can_exit then
                uitext("Hold", 123, 16, "right", self.exitlength, true)
                uitext(": Exit", 21, 16, "right", self.exitlength, true, true)
            end

            love.graphics.setColor(1, 1, 1, 1)
            local x = (diroffsets["right"][1] * 260) / (self.drawpos * 260)
            local y = (diroffsets["right"][1] * 260) / (self.drawpos * 260)
            love.graphics.draw(Input.getTexture("confirm"), SCREEN_WIDTH - 195 + x, SCREEN_HEIGHT - 100, 0, 2, 2)
            love.graphics.draw(Input.getTexture("menu"), SCREEN_WIDTH - 133 + x, SCREEN_HEIGHT - 72, 0, 2, 2)

            if self.piano.can_exit then
                love.graphics.setColor(1, 1 - self.exitlength, 1 - self.exitlength, 1)
                love.graphics.draw(Input.getTexture("cancel"), SCREEN_WIDTH - 119 + y, SCREEN_HEIGHT - 44, 0, 2, 2)
            end
        else
            uitext("[Z] : Play Piano", 20, 72, "right")
            uitext("Hold [C] : Reset", 20, 44, "right", self.resetlength, false)

            if self.piano.can_exit then
                uitext("Hold [X] : Exit", 20, 16, "right", self.exitlength, true)
            end
        end
    else
        if self.piano.can_exit == true then
            if Input.usingGamepad() then
                uitext(": Play", 21, 44, "right")
                uitext("Hold", 123, 16, "right", self.exitlength, true)
                uitext(": Exit", 21, 16, "right", self.exitlength, true, true)
                love.graphics.setColor(1, 1, 1, 1)
                local x = (diroffsets["right"][1] * 260) / (self.drawpos * 260)
                local y = (diroffsets["right"][1] * 260) / (self.drawpos * 260)
                love.graphics.draw(Input.getTexture("confirm"), SCREEN_WIDTH - 118 + x, SCREEN_HEIGHT - 72, 0, 2, 2)
                love.graphics.setColor(1, 1 - self.exitlength, 1 - self.exitlength, 1)
                love.graphics.draw(Input.getTexture("cancel"), SCREEN_WIDTH - 118 + y, SCREEN_HEIGHT - 44, 0, 2, 2)
            else
                uitext("[Z] : Play", 21, 44, "right")
                uitext("Hold [X] : Exit", 21, 16, "right", self.exitlength, true)
            end
        else
            if Input.usingGamepad() then
                uitext(": Play", 21, 16, "right")
                love.graphics.setColor(1, 1, 1, 1)
                local x = (diroffsets["right"][1] * 260) / (self.drawpos * 260)
                love.graphics.draw(Input.getTexture("confirm"), SCREEN_WIDTH - 118 + x, SCREEN_HEIGHT - 44, 0, 2, 2)
            else
                uitext("[Z] : Play", 21, 16, "right")
            end
        end
    end
end

return MovingPianoUI