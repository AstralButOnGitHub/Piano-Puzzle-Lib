---@class PasswordPanel : Event
---@overload fun(...) : PasswordPanel
local PasswordPanel, super = Class(Event)

function PasswordPanel:init(data)
    super.init(self, data)
    self.properties = data.properties or {}

    self.pattern = self.properties["pattern"] or "uurrddllcc"
    self.part = self.properties["part"] or "start" -- (start, midleft, midright, end)
    self.siner = 0
    self.hintcol = self.properties["hintcolor"] or {105/255, 141/255, 230/255, 1}

    self.flag, self.inverted, self.flag_value = TiledUtils.parseFlagProperties("flag", "inverted", "value", nil, self.properties)

    self.is_active = false
    self:updateActive()

    self.targetalpha = self.is_active and 1 or 0
    self.alpha = self.targetalpha
end

function PasswordPanel:onLoad()
    self.layer = self.layer + 0.1
    super.onLoad(self)
end

function PasswordPanel:updateActive()
    local success = false

    if self.flag then
        local value = Game:getFlag(self.flag) or (self.world and self.world.map:getFlag(self.flag))

        if self.flag_value ~= nil then
            success = (value == self.flag_value)
        else
            success = (value or false)
        end
    else
        success = true
    end

    self.is_active = (success ~= self.inverted)
end

function PasswordPanel:update()
    self:updateActive()
    super.update(self)
end

function PasswordPanel:draw()
    self.targetalpha = self.is_active and 1 or 0
    self.alpha = MathUtils.approach(self.alpha, self.targetalpha, 1 / 30)
    super.draw(self)
    local drawspace = 8
    local spwid = 22
    local width = (#self.pattern - 1) * (drawspace + spwid)
    self.siner = self.siner + 1

    for i = 1, #self.pattern, 1 do
        local sprangle = 0
        local scale = 2
        local spr = Assets.getTexture("ui/password_arrow")
        local num = 0
        local char = string.sub(self.pattern, i, i)
        if char == "u" then
            num = 3
        elseif char == "d" then
            num = 7
        elseif char == "l" then
            num = 1
        elseif char == "r" then
            num = 5
        end
        local xloc = (-(width / 2)) + ((spwid + drawspace) * i)
        local yloc = (math.sin((self.siner + (i * 4)) / 8) * 4)
        local col = ColorUtils.mergeColor(self.hintcol, COLORS.white, MathUtils.clamp(0.5 + (math.sin((self.siner - (i * 30)) / 15) * 0.25), 0, 1))

        if num ~= 0 then
            sprangle = (num * 45) - 180 - 45
        else
            spr = Assets.getTexture("ui/circle_7x7")
            scale = 2
        end

        love.graphics.setColor(col[1], col[2], col[3], self.alpha)
        love.graphics.draw(spr, xloc, yloc, math.rad(sprangle), scale, scale, 6, 6)

        if (i == 1 and self.part == "start") then
            love.graphics.setColor(col[1], col[2], col[3], self.alpha)
            love.graphics.draw(Assets.getTexture("ui/musicstaff_0"), xloc - 40, ((math.sin((self.siner + ((i - 1) * 4)) / 8) * 4)) - 28, 0, scale, scale)
        end
        if (i == #self.pattern - 1 and self.part == "end") then
            love.graphics.setColor(col[1], col[2], col[3], self.alpha)
            love.graphics.draw(Assets.getTexture("ui/musicstaff_1"), xloc + 46, ((math.sin((self.siner + ((i + 1) * 4)) / 8) * 4)) - 28, 0, scale, scale)
        end

        -- unused types?
        if (i == #self.pattern - 1 and self.part == "midleft") then
            love.graphics.setColor(col[1], col[2], col[3], self.alpha)
            love.graphics.draw(Assets.getTexture("ui/slurmid"), xloc + 20, ((math.sin((self.siner + ((i * 4) + 4)) / 8) * 4)) - 26, 0, scale, scale)
        end
        if (i == 1 and self.part == "midright") then
            love.graphics.setColor(col[1], col[2], col[3], self.alpha)
            love.graphics.draw(Assets.getTexture("ui/slurmid"), (xloc + 20) - spwid - drawspace - 6, ((math.sin((self.siner + ((i * 4) + 4)) / 8) * 4)) - 26, 0, scale, scale)
        end

        love.graphics.setColor(1, 1, 1, 1)
    end
end

return PasswordPanel