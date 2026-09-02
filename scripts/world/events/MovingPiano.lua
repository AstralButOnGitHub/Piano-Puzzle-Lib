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

    self.pianosprite = Sprite("world/events/movingpiano_"..self.type)
    self.pianosprite.x = -4
    self.pianosprite.y = -20
    self:addChild(self.pianosprite)
    self:setSprite("world/events/movingpianocarpet")
    self.sprite.layer = self.layer - 0.1
    self.pianosprite.layer = self.layer
    self.pianosprite.scale_x = 2
    self.pianosprite.scale_y = 2

    self:setHitbox(6, 34, 68, 16)
    self.fakeCollider = Hitbox(self, 0, 0, 80, 80)
    self.solid = true

    self.camera_posx = self.properties["camera_posx"] or nil
    self.camera_posy = self.properties["camera_posy"] or nil

    self.characters = {}
    self.player = nil
    self.current_bookshelf = self
    self.twotone_id = 1
    self.ui = nil
    self.exiting = false

    self.newcollider = Hitbox(self, 1, 1, 78, 78)
    self.siner = 0

    self.sound = self.properties["sound"] or "piano"

    self.fakeout = Game.world.map:getEvent(self.properties["fakeout"])
    self.faked = self:getFlag("faked", false)

    self.can_exit = self.properties["can_exit"] or true
    self.hasinputbuffering = false

    self.ralshakex = 0
    self.ralsei_knocked_down = 0
    self.dusttimer = 0
end

function MovingPiano:land()
    self.yoffset = 0
    self.jumpvel = 0
    self.jumping = false

    Assets.playSound("impact")
    self.pianosprite:shake(12, 0)
end

function MovingPiano:stopMoving(prev_x, prev_y)
    local snap_x = math.floor(prev_x / 10 + 0.5) * 10
    local snap_y = math.floor(prev_y / 10 + 0.5) * 10
    local dir = self.movedir

    self:setSpeed(0, 0)
    self.moving = false
    self.movedir = nil
    self:setPosition(snap_x, snap_y)
    local dist = math.abs(self.x - self.start_x) + math.abs(self.y - self.start_y)
    if dist > 0 then
        Assets.playSound("bomb")

        if dir == "up" or dir == "down" then
            self.pianosprite:shake(0, 4)
        elseif dir == "left" or dir == "right" then
            self.pianosprite:shake(4, 0)
        end
    end

    PianoPuzzleLib:updateFloorHoles()
    if self.storedinputs[1] ~= nil and self.hasinputbuffering then
        self:getMovinFoo(self.storedinputs[1])

        table.remove(self.storedinputs, 1)
        table.remove(self.storedinputdementia, 1)
    end
end

function MovingPiano:getSortPosition()
    return self:getRelativePos(0, 34)
end

function MovingPiano:onInteract(player, dir)
    if dir == "up" then
        self.characters = Game.world.followers
        Game.world.followers = {}
        self.player = player
        self.player:setState("PIANO")
        local krx = self.x + 40
        local kry = self.y + 40 + 53
        local dist = math.max(MathUtils.round(MathUtils.dist(self.player.x, self.player.y, krx, kry) / 4), 1)
        dist = dist / 30
        self.world:setCameraAttached(false)
        self.player:walkTo(krx, kry, dist, "up")
        for _, chara in ipairs(self.characters) do
            chara:walkTo(krx, kry, dist, "up")
        end
        Game.world.can_open_menu = false
        Game.world.timer:after(dist + 0.01, function()
            self.player:setFacing("up")
            self.player:setSprite("piano_holdon")
            self.player:setParent(self)
            self.player:setPosition(27, 68)
            for i, chara in ipairs(self.characters) do
                self.characters[i] = chara:convertToCharacter()
                chara:remove()
                chara = self.characters[i]
                chara:setParent(self)
                chara:setPosition(27 + (20 * i), 68 + 20)
            end

            self.show_ui = true
            if not self.faked and self.fakeout then
                self.fakeout.controlled = true
            end
            self.controlled = true
            self.piano = self
        end)
    end
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
        player:setPosition(self.x + 40, self.y + 40 + 53)
        Game.world.can_open_menu = true
        self.world:setCameraAttached(true)
        self.player:resetSprite()
        for i, chara in ipairs(self.characters) do
            local follower = chara:convertToFollower()
            chara:remove()
            follower:setPosition(self.player.x + 20, self.player.y + 20)
            Game.world:detachFollowers()
            follower.history = {}
        end

        self.player = nil
        self.exiting = false
        Game.world:attachFollowersImmediate()
    end)
end

function MovingPiano:doCollision(prev_x, prev_y)
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
                    if self.newcollider:meetsCollider(event.fakeCollider or event.collider) then
                        if self.fakeCollider:meetsCollider(event.fakeCollider or event.collider) then
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

function MovingPiano:playNote(dir, shownote)
    local dir_char = "c"
    if dir == "up" then
        dir_char = "u"
    elseif dir == "down" then
        dir_char = "d"
    elseif dir == "left" then
        dir_char = "l"
    elseif dir == "right" then
        dir_char = "r"
    else
        dir_char = "c"
    end
    dir = dir_char
    local pitch = 1
    shownote = shownote or true

    if dir == "u" then
        pitch = 0.5
    elseif dir == "d" then
        pitch = 1.19
    elseif dir == "l" then
        pitch = 1.12
    elseif dir == "r" then
        pitch = 0.8928571428571428
    end

    local arrowvel = {
        ["u"] = {0, -1},
        ["d"] = {0, 1},
        ["l"] = {-1, 0},
        ["r"] = {1, 0},
        ["c"] = {0, 0},
    }
    local arrowvel2 = {
        ["u"] = {-1, -1},
        ["d"] = {1, 1},
        ["l"] = {-1, 1},
        ["r"] = {1, -1},
        ["c"] = {0, 0},
    }

    local drawx = (self.sprite.width)
    local drawy = -36 - 46 + 10

    local arrowstuff = {
        ["u"] = {drawx, drawy - 25 + math.sin((self.siner + 126) / 9) * 2, math.rad(180)},
        ["d"] = {drawx, drawy + 25 + math.sin((self.siner + 42) / 9) * 2, 0},
        ["l"] = {drawx - 25, drawy + math.sin((self.siner + 168) / 9) * 2, math.rad(90)},
        ["r"] = {drawx + 25, drawy + math.sin((self.siner + 84) / 9) * 2, math.rad(270)},
        ["c"] = {drawx - 7, drawy - 7 + math.sin((self.siner + 210) / 9) * 2, 0},
    }

    if shownote then
        local arrow = Sprite("ui/arrow_9x9", arrowstuff[dir][1] + -arrowvel2[dir][1] * 10, arrowstuff[dir][2] + -arrowvel2[dir][2] * 10)
        if dir == "c" then
            arrow = Sprite("ui/circle_7x7", arrowstuff[dir][1], arrowstuff[dir][2])
        end
        arrow.layer = 49600
        arrow.color = self.iconcolor_bright
        arrow.rotation = arrowstuff[dir][3]
        arrow.scale_x = arrow.scale_x * 2
        arrow.scale_y = arrow.scale_y * 2
        local speed = 4
        self:addChild(arrow)
        arrow:setSpeed(arrowvel[dir][1] * speed, arrowvel[dir][2] * speed)
        arrow:fadeOutAndRemove(0.5)
    end

    Assets.playSound("piano", 0.7, pitch)
end

function MovingPiano:updateRiders()
    if self.controlled then
        local myhspeed, _ = self:getSpeedXY()
        for _, follower in ipairs(self.characters) do
            if follower:includes(Character) then
                if follower.actor.name == "Susie" then
                    local susie = follower
                    susie:setPosition(36 + 25, 80 + ((self.yoffset / 8)))
                    if self.yoffset < 0 then
                        susie:setSprite("fall_brace")
                        susie.flip_x = myhspeed < 0 and self.yoffset < 0
                    else
                        susie:setSprite("walk/up_1")
                    end
                    if (self.pianosprite.graphics.shake_x >= 9) then
                        susie:setSprite("landed_1")
                        susie.flip_x = myhspeed < 0 and self.yoffset < 0
                    end
                end

                if follower.actor.name == "Ralsei" then
                    local ralsei = follower
                    local xoff = 0

                    if (self.ralshakex > 0) then
                        xoff = (((self.ralshakex % 2) - 0.5) * 2 * self.ralshakex) - 8
                    end
                    if self.yoffset < 0 then
                        if myhspeed < 0 then
                            xoff = xoff - 10
                        else
                            xoff = xoff - 14
                        end
                    end
                    ralsei:setPosition(25 + xoff, 80 + ((self.yoffset / 4) * 1.2))

                    if self.yoffset < 0 then
                        self.ralsei_knocked_down = 16

                        if myhspeed > 0 then
                            ralsei:setSprite("shocked_right_landed_0")
                        else
                            ralsei:setSprite("shocked_left_landed_0")
                        end
                    elseif self.ralsei_knocked_down <= 0 then
                        ralsei:setSprite("walk/up_1")
                    else
                        self.ralsei_knocked_down = self.ralsei_knocked_down - 1

                        if self.ralsei_knocked_down == 0 then
                            self.ralshakex = 8
                        end

                        if myhspeed > 0 then
                            ralsei:setSprite("shocked_right_landed_1")
                        else
                            ralsei:setSprite("shocked_left_landed_1")
                        end

                        self.ralshakex = self.ralshakex - 1
                    end
                end
            end
        end
    end
end

function MovingPiano:update()
    super.update(self)

    self.dusttimer = self.dusttimer + 1
    if self.moving and not self.jumping then
        if (math.floor(self.dusttimer) % 2) == 0 then
            local xOffset = 0.5
            local yOffset = (MathUtils.random(0.6) + 0.2) * 20

            if (self.vely ~= 0) then
                xOffset = yOffset
                yOffset = 0.5
            else
                yOffset = yOffset -2
            end

            local dust = Sprite("effects/climb_dust_small")
            dust:setPosition(self.x + (xOffset * dust.width), self.y + (yOffset * dust.height))
            dust.layer = self.layer - 0.1
            dust.scale_x = dust.scale_x * 2
            dust.scale_y = dust.scale_y * 2
            dust:setSpeed(MathUtils.random(-1, 1), 0)
            dust:play(0.1, false, function(sprite)
                sprite:remove()
            end)
            Game.world:addChild(dust)
        end
    end

    self:updateRiders()
    if self.show_ui then
        if self.ui == nil then
            self.ui = MovingPianoUI(self)
            Game.stage:addChild(self.ui)
        end
    end
    if self.controlled then
        if not self.faked and self.fakeout then
            Game.world.camera.x = MathUtils.lerp(Game.world.camera.x, self.fakeout.x, 0.15)
            Game.world.camera.y = MathUtils.lerp(Game.world.camera.y, self.fakeout.y, 0.15)
        else
            Game.world.camera.x = MathUtils.lerp(Game.world.camera.x, self.x + 40, 0.15)
            Game.world.camera.y = MathUtils.lerp(Game.world.camera.y, self.y + 40 + (self.yoffset), 0.15)
        end
    end

    if not self.current_bookshelf or not self.current_bookshelf.controlled or not self.player or self.exiting then
        return
    end

    if self.can_exit and Input.down("cancel") and self.ui.drawpos >= 1 and not self.current_bookshelf.moving and self.current_bookshelf.controlled then
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

    if Input.down(dir) and Input.pressed("confirm", false) and self.current_bookshelf and not self.moving then
        if self.fakeout ~= nil and not self.faked then
            self:setFlag("faked", true)
            self.faked = self:getFlag("faked", false)
            self.fakeout.controlled = false
        end
        if self.current_bookshelf.moving and dir ~= nil and (#self.current_bookshelf.storedinputs < 1 and dir ~= self.current_bookshelf.movedir) and dir ~= self.current_bookshelf.storedinputs[1] then
            table.insert(self.current_bookshelf.storedinputs, dir)
            table.insert(self.current_bookshelf.storedinputdementia, 0)
            return
        end
        if self.current_bookshelf:getMovinFoo(dir) then
            dir = nil
        else
            self:playNote(dir, true)
        end
    end
end

function MovingPiano:draw()
    super.draw(self)
    self.siner = self.siner + 1
    local drawx = (self.sprite.width)
    local drawy = -36 - 46 + 10

    if self.ui and not (self.fakeout ~= nil and not self.faked) then
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
        love.graphics.print(TableUtils.dump(self.storedinputs), 0, 20)
        love.graphics.print(TableUtils.dump(self.storedinputdementia), 0, 30)
    end
end

return MovingPiano