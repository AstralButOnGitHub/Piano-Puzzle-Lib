---@class MovingObject : Event
---@overload fun(...) : MovingObject
local MovingObject, super = Class(Event)

function MovingObject:init(data)
    super.init(self, data)

    self.solid = true

    self.movedir = nil
    self.moving = false
    self:setHitbox(0, 80, 80, 80)
    self.collider.width = 80
    self.collider.height = 80

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

    self.jumpvel = 0
    self.yoffset = 0
    self.jumping = false
    self.shadow = {0, 0, 80, 80}

    self.hasinputbuffering = true
end

function MovingObject:onLoad()
    super.onLoad(self)
    PianoPuzzleLib:updateFloorHoles()
end

function MovingObject:setSpeed(vx, vy)
    self.velx, self.vely = vx, vy
end

function MovingObject:getSpeedXY()
    return self.velx, self.vely
end

function MovingObject:getMovinFoo(dir)
    if not self.moving and not self.resetting then
        self.start_x = self.x
        self.start_y = self.y

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

function MovingObject:stopMoving(prev_x, prev_y)
    local snap_x = math.floor(prev_x / 10 + 0.5) * 10
    local snap_y = math.floor(prev_y / 10 + 0.5) * 10

    self:setSpeed(0, 0)
    self.moving = false
    self.movedir = nil
    self:setPosition(snap_x, snap_y)
    local dist = math.abs(self.x - self.start_x) + math.abs(self.y - self.start_y)
    if dist > 0 then
        Assets.playSound("wing")
    end

    PianoPuzzleLib:updateFloorHoles()
    if self.storedinputs[1] ~= nil and self.hasinputbuffering then
        self:getMovinFoo(self.storedinputs[1])

        table.remove(self.storedinputs, 1)
        table.remove(self.storedinputdementia, 1)
    end
end

function MovingObject:doCollision(prev_x, prev_y)
    if self.jumping then
        return false
    end
    local dx, dy = 0, 0
    if self.movedir == "up" then
        dy = -80
    elseif self.movedir == "down" then
        dy = 80
    elseif self.movedir == "left" then
        dx = -80
    elseif self.movedir == "right" then
        dx = 80
    end

    self.newcollider.x = 1 + dx
    self.newcollider.y = 81 + dy

    local vx, vy = self:getSpeedXY()
    if vx ~= 0 or vy ~= 0 then
        for _, collider in ipairs(Game.world.map.piano_collision) do
            if self.newcollider:meetsCollider(collider) then
                if self:meetsCollider(collider) then
                    self:stopMoving(prev_x, prev_y)
                    return true
                end
            end
        end

        if self.moving then
            for _, event in ipairs(Game.world.children) do
                if event ~= self and event:includes(MovingObject) then
                    if self.newcollider:meetsCollider(event.fakeCollider or event.collider) then
                        if self:meetsCollider(event.fakeCollider or event.collider) then
                            self:stopMoving(prev_x, prev_y)
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function MovingObject:jump()
    if not self.jumping then
        self.jumpvel = -16
        self.yoffset = self.jumpvel
        self.jumping = true
        Assets.playSound("piano_jump")
    end
end

function MovingObject:land()
    self.yoffset = 0
    self.jumpvel = 0
    self.jumping = false

    Assets.playSound("impact")
    self:shake(12, 0)
end

function MovingObject:update()
    if self.jumping then
        self.jumpvel = self.jumpvel + 0.65 * DTMULT
        self.yoffset = self.yoffset + self.jumpvel

        if self.yoffset >= 0 then
            self:land()
        end
    end

    for _ = 1, math.floor(math.abs(self.velx * DTMULT)) do
        local last_x = self.x
        self.x = self.x + (self.velx > 0 and 1 or -1)

        if self:doCollision(last_x, self.y) then
            self.x = last_x
            self.velx = 0
            break
        end
    end

    for _ = 1, math.floor(math.abs(self.vely * DTMULT)) do
        local last_y = self.y
        self.y = self.y + (self.vely > 0 and 1 or -1)

        if self:doCollision(self.x, last_y) then
            self.y = last_y
            self.vely = 0
            break
        end
    end

    if self.moving and self.velx == 0 and self.vely == 0 then
		self:stopMoving(self.x, self.y)
	end

    for i = #self.storedinputdementia, 1, -1 do
        if self.storedinputs[i] == nil then
            table.remove(self.storedinputs, i)
            table.remove(self.storedinputdementia, i)
        else
            self.storedinputdementia[i] = self.storedinputdementia[i] + (DTMULT / 30)

            if self.storedinputdementia[i] > 0.5 then
                table.remove(self.storedinputs, i)
                table.remove(self.storedinputdementia, i)
            end
        end
    end
    local prev_x, prev_y = self.x, self.y
    self.sintimer = self.sintimer + (DTMULT / (15 / 2))

    super.update(self)

    if self.controls_alpha == 1 then
        self.can_control = true
    end

    if self.resetting then
        self.reset_timer = self.reset_timer + (DTMULT / 30)
        self.x = PianoPuzzleLib:ease(self.x, self.resetx, self.reset_timer, "outElastic")
        self.y = PianoPuzzleLib:ease(self.y, self.resety, self.reset_timer, "outElastic")
        if self.reset_timer >= 0.9 then
            self.x = self.resetx
            self.y = self.resety
            self.resetting = false
            self.reset_timer = 0
        end
        return
    end

    if self.controlled then
        self.controls_alpha = math.min(1, self.controls_alpha + (DT / 0.5))
    else
        self.controls_alpha = math.max(0, self.controls_alpha - (DT / 1.0))
    end
end

function MovingObject:draw()
    if DEBUG_RENDER then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(tostring(math.abs(self.yoffset)), 0, 120)
        love.graphics.print(tostring(self.jumping), 0, 140)
    end
    local sx, sy, sw, sh = TableUtils.unpack(self.shadow)
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", sx, sy, sw, sh)
    love.graphics.translate(0, math.floor(self.yoffset))
    love.graphics.setColor(1, 1, 1, 1)
    super.draw(self)
end

return MovingObject