---@class MovingBookshelf : MovingObject
---@overload fun(...) : MovingBookshelf
local MovingBookshelf, super = Class(MovingObject)

function MovingBookshelf:init(data)
    super.init(self, data)
    self.properties = data.properties or {}

    self.type = self.properties["type"] or "blue"
    self.icon = "ui/"..self.type.."_icon"
    if Assets.getTexture(self.icon) == nil then
        self.icon = "ui/blue_icon"
    end

    self.iconcolor = self.properties["iconcolor"] or COLORS.black
    self.iconcolor_bright = self.properties["iconcolor_bright"] or COLORS.gray
    if self.type == "blue" then
        self.iconcolor = {21/255, 39/255, 87/255, 1}
        self.iconcolor_bright = {105/255, 141/255, 230/255, 1}
    elseif self.type == "green" then
        self.iconcolor = {0/255, 66/255, 0/255, 1}
        self.iconcolor_bright = {66/255, 191/255, 66/255, 1}
    elseif self.type == "pink" then
        self.iconcolor = {80/255, 14/255, 65/255, 1}
        self.iconcolor_bright = {215/255, 144/255, 199/255, 1}
    elseif self.type == "red" then
        self.iconcolor = {84/255, 18/255, 29/255, 1}
        self.iconcolor_bright = {225/255, 100/255, 121/255, 1}
    elseif self.type == "twotone_green" then
        self.iconcolor = {37/255, 48/255, 1/255, 1}
        self.iconcolor_bright = {145/255, 184/255, 22/255, 1}
    elseif self.type == "twotone_purple" then
        self.iconcolor = {78/255, 12/255, 78/255, 1}
        self.iconcolor_bright = {223/255, 60/255, 224/255, 1}
    end

    self.sound = self.properties["sound"] or "musicbox"

    if self.type == "blue" then
        self.sound = "musicbox"
    elseif self.type == "green" then
        self.sound = "violin"
    elseif self.type == "pink" then
        self.sound = "square_wave"
    elseif self.type == "red" then
        self.sound = "choir"
    elseif self.type == "twotone_green" then
        self.sound = "piano_deep"
    elseif self.type == "twotone_purple" then
        self.sound = "piano"
    end

    self:setHitbox(0, 80, 80, 80)
    self:setOrigin(0.5, 0.5)
    self.solid = true

    self.movedir = nil
    self.moving = false
    self.collider.width = 80
    self.collider.height = 80

    self.piano = nil
    self.controlled = false

    self.can_control = false
    self.controls_alpha = 0

    self.subtractive = false
    self.subcollider = Hitbox(self, 0, 0, 80, 80)

    self.newcollider = Hitbox(self, 1, 81, 78, 78)

    self.resetting = false
    self.reset_timer = 0
    self.resetx = self.x
    self.resety = self.y

    self.sintimer = 0
    self.storedinputs = {}
    self.storedinputdementia = {}

    self.velx, self.vely = 0, 0
    self.shadow = {0, 80, 80, 80}
end

function MovingBookshelf:getMovinFoo(dir)
    if not self.moving and not self.resetting then
        self.start_x = self.x
        self.start_y = self.y
        if dir == "up" then
            Assets.playSound(self.sound, 0.5, 1.19)
        elseif dir == "right" then
            Assets.playSound(self.sound, 0.5, 1.12)
        elseif dir == "down" then
            Assets.playSound(self.sound, 0.5, 1)
        elseif dir == "left" then
            Assets.playSound(self.sound, 0.5, 0.8928571428571428)
        end

        if self.pre_colliders then
            for _, data in ipairs(self.pre_colliders) do
                Game.world.map.collision[data.index] = data.collider
            end
            self.pre_colliders = nil
        end

        self.moving = true
        self.movedir = dir
        local speed = 18
        if dir == "up" then
            self:setSpeed(0, -speed)
        end
        if dir == "down" then
            self:setSpeed(0, speed)
        end
        if dir == "left" then
            self:setSpeed(-speed, 0)
        end
        if dir == "right" then
            self:setSpeed(speed, 0)
        end
    end
end

function MovingBookshelf:update()
    super.update(self)
    self:setSprite("world/events/2x2shelf_"..self.type.."_0")
end

function MovingBookshelf:draw()
    super.draw(self)
    if self.controlled then
        love.graphics.setColor({1, 1, 1, 0.9 + math.sin(self.sintimer) * 0.1})
        love.graphics.draw(Assets.getTexture("world/events/2x2shelf_"..self.type.."_1"), 0, 0, 0, 2, 2)
    end

    if self.controls_alpha < 0 then
        return
    end

    local dir = nil
    if self.controlled and self.can_control then
        if Input.down("up") then
            dir = "up"
        elseif Input.down("down") then
            dir = "down"
        elseif Input.down("left") then
            dir = "left"
        elseif Input.down("right") then
            dir = "right"
        end
    end

    if DEBUG_RENDER then
        self.subcollider:draw(1, 0, 0, 1)
        self.newcollider:draw()
        love.graphics.setColor(COLORS.white)
        local vx, vy = self:getSpeedXY()
        local x, y = self:getPosition()
        love.graphics.print(x..", "..y, 0, -20)
        love.graphics.print(vx..", "..vy, 0, -10)
        love.graphics.print((tostring(self.moving) or "false")..", "..(self.movedir or "nil"), 0, 0)
        love.graphics.print(self.reset_timer, 0, 10)
        love.graphics.print(TableUtils.dump(self.storedinputs), 0, 20)
        love.graphics.print(TableUtils.dump(self.storedinputdementia), 0, 30)
    end

    local tex = Assets.getTexture("ui/arrow_8x8")

    local white_color = {1, 1, 1, self.controls_alpha}

    local r, g, b, _ = TableUtils.unpack(self.iconcolor)
    local base_off_color = {r, g, b, 1 - self.controls_alpha}
    local r2, g2, b2, _ = TableUtils.unpack(self.iconcolor_bright)
    local base_color = {r2, g2, b2, self.controls_alpha}

    love.graphics.setColor(dir == "up" and white_color or base_color)
    love.graphics.draw(tex, 40, 16, math.rad(180), 2, 2, 4, 4)

    love.graphics.setColor(dir == "down" and white_color or base_color)
    love.graphics.draw(tex, 40, 64, math.rad(0), 2, 2, 4, 4)

    love.graphics.setColor(dir == "left" and white_color or base_color)
    love.graphics.draw(tex, 16, 40, math.rad(90), 2, 2, 4, 4)

    love.graphics.setColor(dir == "right" and white_color or base_color)
    love.graphics.draw(tex, 64, 40, math.rad(270), 2, 2, 4, 4)

    love.graphics.setColor(base_off_color)
    love.graphics.draw(Assets.getTexture(self.icon), 30, 30, 0, 2, 2)
    love.graphics.setColor(dir == nil and white_color or base_color)
    love.graphics.draw(Assets.getTexture(self.icon), 30, 30, 0, 2, 2)

    love.graphics.setColor(COLORS.white)
end

return MovingBookshelf