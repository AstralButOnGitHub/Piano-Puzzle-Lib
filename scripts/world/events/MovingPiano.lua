---@class MovingPiano : MovingObject
---@overload fun(...) : MovingPiano
local MovingPiano, super = Class(MovingObject)

function MovingPiano:init(data)
    super.init(self, data)
    self.properties = data.properties or {}

    self.type = self.properties["type"] or "pink"

    self.icontype = self.properties["icontype"] or "blue"

    self.iconcolor = self.properties["iconcolor"] or COLORS.black
    self.iconcolor_bright = self.properties["iconcolor_bright"] or COLORS.gray
    if self.icontype == "blue" then
        self.iconcolor = {21/255, 39/255, 87/255, 1}
        self.iconcolor_bright = {105/255, 141/255, 230/255, 1}
    elseif self.icontype == "green" then
        self.iconcolor = {0/255, 66/255, 0/255, 1}
        self.iconcolor_bright = {66/255, 191/255, 66/255, 1}
    elseif self.icontype == "pink" then
        self.iconcolor = {80/255, 14/255, 65/255, 1}
        self.iconcolor_bright = {215/255, 144/255, 199/255, 1}
    elseif self.icontype == "red" then
        self.iconcolor = {84/255, 18/255, 29/255, 1}
        self.iconcolor_bright = {225/255, 100/255, 121/255, 1}
    elseif self.icontype == "twotone_green" then
        self.iconcolor = {37/255, 48/255, 1/255, 1}
        self.iconcolor_bright = {145/255, 184/255, 22/255, 1}
    elseif self.icontype == "twotone_purple" then
        self.iconcolor = {78/255, 12/255, 78/255, 1}
        self.iconcolor_bright = {223/255, 60/255, 224/255, 1}
    end

    local pianosprite = Sprite("world/events/movingpiano_"..self.type)
    pianosprite.x = -4
    pianosprite.y = -20
    self:addChild(pianosprite)
    self:setSprite("world/events/movingpianocarpet")
    self.sprite.layer = self.layer - 0.1
    pianosprite.layer = self.layer
    pianosprite.scale_x = 2
    pianosprite.scale_y = 2

    self:setHitbox(6 -4, 22*2 - 20, 78, 16*2)
    self.fakeCollider = Hitbox(self, 0, 0, 80, 80)
    self.solid = true

    self.camera_posx = self.properties["camera_posx"] or nil
    self.camera_posy = self.properties["camera_posy"] or nil

    self.player = nil
    self.current_bookshelf = self
    self.twotone_id = 1
    self.ui = nil
    self.exiting = false

    self.newcollider = Hitbox(self, 1, 1, 78, 78)
    self.siner = 0
end

function MovingPiano:onInteract(player, dir)
    if dir == "up" then
        self.player = player
        self.player:setState("PIANO")
        local krx = self.x
        local kry = self.y + 53
        local dist = math.max(MathUtils.round(MathUtils.dist(self.player.x, self.player.y, krx, kry) / 4), 1)
        dist = dist / 30
        self.world:setCameraAttached(false)
        self.player:walkTo(krx, kry, dist, "up");
        Game.world.can_open_menu = false
        Game.world.timer:after(dist, function()
            self.player:setFacing("up")
            self.player:resetSprite()
            self.player:setParent(self)
            if self.type == "twotone" then
                if self.twotone_id ~= 1 then
                    self.player:setPosition(35, 92)
                else
                    self.player:setPosition(75, 92)
                end
            else
                self.player:setPosition(45, 94)
            end
            self.show_ui = true
            self.controlled = true
            self.piano = self
        end)
    end
end

function MovingPiano:doCollision(prev_x, prev_y)
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
    self.newcollider.y = 1 + dy

    local vx, vy = self:getSpeedXY()
    if vx ~= 0 or vy ~= 0 then
        for _, collider in ipairs(Game.world.map.piano_collision) do
            if self.newcollider:meetsCollider(collider) then
                if self.fakeCollider:meetsCollider(collider) then
                    self:stopMoving(prev_x, prev_y)
                    return true
                end
            end
        end

        if self.moving then
            for _, event in ipairs(Game.world.children) do
                if event ~= self and event:includes(MovingObject) then
                    if self.newcollider:meetsCollider(event.collider) then
                        if self.fakeCollider:meetsCollider(event.collider) then
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

function MovingPiano:exit()
    if self.exiting or not self.player then
        return
    end

    self.exiting = true

    local player = self.player

    self.show_ui = false
    self.ui.exitlength = 0
    self.controlled = false
    self.ui.drawpostarget = -0.1

    Game.world.timer:after(1, function()
        if not player then
            self.exiting = false
            return
        end

        player:setState("WALK")
        player:setFacing("down")
        player:setParent(Game.world)
        player:setPosition(self.x + 4, self.y + 55 + 20)

        Game.world.can_open_menu = true
        self.world:setCameraAttached(true)

        self.player = nil
        self.exiting = false
    end)
end

function MovingPiano:update()
    super.update(self)
    if self.show_ui then
        if self.ui == nil then
            self.ui = RemotePianoUI(self)
            Game.stage:addChild(self.ui)
        end
    end
    if self.current_bookshelf then
        if self.current_bookshelf.controlled == false then
            if self.player then
                Game.world.camera.x = MathUtils.lerp(Game.world.camera.x, self.x, 0.2)
                Game.world.camera.y = MathUtils.lerp(Game.world.camera.y, self.y + 15, 0.2)
            end
        else
            if self.camera_posx ~= nil and self.camera_posy ~= nil then
                Game.world.camera.x = MathUtils.lerp(Game.world.camera.x, self.camera_posx, 0.15)
                Game.world.camera.y = MathUtils.lerp(Game.world.camera.y, self.camera_posy, 0.15)
            else
                Game.world.camera.x = MathUtils.lerp(Game.world.camera.x, self.current_bookshelf.x, 0.15)
                Game.world.camera.y = MathUtils.lerp(Game.world.camera.y, self.current_bookshelf.y, 0.15)
            end
        end
    end

    if not self.current_bookshelf or not self.current_bookshelf.controlled or not self.player or self.exiting then
        return
    end

    if Input.down("cancel") and self.ui.drawpos >= 1 and not self.current_bookshelf.moving and self.current_bookshelf.controlled and not self.current_bookshelf.resetting then
        self.ui.exitlength = MathUtils.clamp(self.ui.exitlength + (DTMULT * 2) / 30, 0, 1)
        if self.ui.exitlength >= 1 then
            self:exit()
        end
    else
        self.ui.exitlength = 0
    end

    if self.type == "twotone" then
        if Input.pressed("menu", false) and self.ui.drawpos >= 1 and not self.current_bookshelf.moving then
            self.twotone_id = self.twotone_id + 1
            if self.twotone_id > 2 then
                self.twotone_id = 1
            end
            self:setBookshelf(self.properties["target_"..self.twotone_id]["id"])

            local target_x = (self.twotone_id ~= 1) and 35 or 75
            Game.world.timer:tween(0.15, self.player, {x = target_x}, "linear")
        end
    else
        if Input.down("menu") and self.ui.drawpos >= 1 and not self.current_bookshelf.moving and self.current_bookshelf.controlled and not self.current_bookshelf.resetting then
            self.ui.resetlength = MathUtils.clamp(self.ui.resetlength + (DTMULT * 2) / 30, 0, 1)
            if self.ui.resetlength >= 1 then
                self:reset()
            end
        else
            self.ui.resetlength = 0
        end
    end
    local dir = nil
    if Input.down("up") then
        dir = "up"
    elseif Input.down("down") then
        dir = "down"
    elseif Input.down("left") then
        dir = "left"
    elseif Input.down("right") then
        dir = "right"
    end

    if Input.down(dir) and Input.pressed("confirm", false) and self.current_bookshelf then
        if self.current_bookshelf.moving and dir ~= nil and (#self.current_bookshelf.storedinputs < 1 and dir ~= self.current_bookshelf.movedir) and dir ~= self.current_bookshelf.storedinputs[1] then
            table.insert(self.current_bookshelf.storedinputs, dir)
            table.insert(self.current_bookshelf.storedinputdementia, 0)
            return
        end
        if self.current_bookshelf:getMovinFoo(dir) then
            dir = nil
        end
    end
end

function MovingPiano:draw()
    super.draw(self)
    self.siner = self.siner + 1
    local drawx = (self.sprite.width)
    local drawy = -36 - 46 + 10

    if self.ui then
        love.graphics.setColor({0, 0, 0, self.ui.drawpos / 2})
        love.graphics.circle("fill", drawx, drawy, 44 + (math.sin(self.siner / 64) * 2))

        local dir = nil
        if self.show_ui then
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

        local r2, g2, b2, _ = TableUtils.unpack(self.iconcolor_bright)
        local white_color = {r2, g2, b2, self.ui.drawpos}
        local base_color = {r2, g2, b2, (94/255) * self.ui.drawpos}

        local tex = Assets.getTexture("ui/arrow_9x9")

        love.graphics.setColor(dir == nil and white_color or base_color)
        love.graphics.draw(Assets.getTexture("ui/circle_7x7"), drawx - 7, drawy - 7 + 4 + math.sin((self.siner + 210) / 9) * 2, 0, 2, 2)

        love.graphics.setColor(dir == "up" and white_color or base_color)
        love.graphics.draw(tex, drawx, drawy - 25 - 2 + math.sin((self.siner + 126) / 9) * 2, math.rad(180), 2, 2, 5, 5)

        love.graphics.setColor(dir == "down" and white_color or base_color)
        love.graphics.draw(tex, drawx, drawy + 25 + 8 + math.sin((self.siner + 42) / 9) * 2, math.rad(0), 2, 2, 5, 5)

        love.graphics.setColor(dir == "left" and white_color or base_color)
        love.graphics.draw(tex, drawx - 25 - 2, drawy + 10 + math.sin((self.siner + 168) / 9) * 2, math.rad(90), 2, 2, 5, 5)

        love.graphics.setColor(dir == "right" and white_color or base_color)
        love.graphics.draw(tex, drawx + 25 + 2, drawy - 6 + math.sin((self.siner + 84) / 9) * 2, math.rad(270), 2, 2, 5, 5)
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
end

return MovingPiano