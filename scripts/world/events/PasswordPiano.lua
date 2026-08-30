---@class PasswordPiano : Event
---@overload fun(...) : PasswordPiano
local PasswordPiano, super = Class(Event)

function PasswordPiano:init(data)
    super.init(self, data)
    self.properties = data.properties or {}

    self:setFlag("hassolved", false)

    self.pattern = self.properties["pattern"] or "uurrddllcc"
    self.note = 0
    self.current_note = nil
    self.cutscene = self.properties["cutscene"] or nil
    self.precutscene = self.properties["precutscene"] or nil

    self.type = self.properties["type"] or "blue"
    self:setSprite("world/events/passwordpiano_"..self.type)
    self:setHitbox(6, 18*2, 40*2, 12*2)
    self.solid = true
    self:setOrigin(0.5, 0.5)

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

    self.player = nil
    self.ui = nil
    self.exiting = false
    self.movingcamera = false
    self.cameramovelength = 0
    self.siner = 0
end

function PasswordPiano:onInteract(player, dir)
    if self.exiting or self.player or self.movingcamera then
        return
    end

    if dir == "up" then
        self.movingcamera = true
        self.player = player
        self.player:setState("PIANO")
        local krx = self.x
        local kry = self.y + 51
        local dist = math.max(MathUtils.round(MathUtils.dist(self.player.x, self.player.y, krx, kry) / 4), 1)
        dist = dist / 30
        self.cameramovelength = dist
        self.world:setCameraAttached(false)
        self.player:walkTo(krx, kry, dist, "up");
        Game.world.can_open_menu = false
        Game.world.timer:after(dist, function()
            self.player:setFacing("up")
            self.player:resetSprite()
            self.show_ui = true
        end)
    end
end

function PasswordPiano:exit(cutscene)
    if self.exiting or not self.player then
        return
    end

    self.exiting = true

    local player = self.player

    if self.ui then
        self.show_ui = false
        self.ui.exitlength = 0
        self.ui.drawpostarget = -0.1
    end

    Game.world.timer:after(1, function()
        if not player then
            self.exiting = false
            return
        end

        player:setState("WALK")
        player:setFacing("down")

        Game.world.can_open_menu = true
        self.world:setCameraAttached(true)

        self.player = nil
        self.exiting = false
        self.movingcamera = false
        if cutscene ~= nil then
            Game.world:startCutscene(cutscene)
        end
    end)
end

function PasswordPiano:playNote(dir)
    local pitch = 1

    if dir == "u" then
        pitch = 0.5
    elseif dir == "d" then
        pitch = 1.19
    elseif dir == "l" then
        pitch = 1.12
    elseif dir == "r" then
        pitch = 0.8928571428571428
    end

    Assets.playSound("piano", 0.7, pitch)
end

function PasswordPiano:update()
    if self.show_ui then
        if self.ui == nil then
            self.ui = PasswordPianoUI(self)
            Game.stage:addChild(self.ui)
        end
    end

    if self.movingcamera then
        Game.world.camera.x = MathUtils.lerp(Game.world.camera.x, self.x, (self.cameramovelength * DTMULT) / 2)
        Game.world.camera.y = MathUtils.lerp(Game.world.camera.y, self.y + 15, 0.2)
    end

    if not self.player or self.exiting or not self.ui then
        return
    end

    if Input.down("x") and self.ui.drawpos >= 1 then
        self.ui.exitlength = MathUtils.clamp(self.ui.exitlength + (DTMULT * 2) / 30, 0, 1)
        if self.ui.exitlength >= 1 then
            self:exit()
        end
    else
        self.ui.exitlength = 0
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
    local skipcode = Input.down("p") and DEBUG_RENDER

    if Input.pressed("z", false) and self.show_ui then
        self.note = self.note + 1

        self.current_note = string.sub(self.pattern, self.note, self.note)

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

        self:playNote(dir_char)

        if self.current_note ~= dir_char then
            self.note = 0
            self.current_note = nil
        end

        if skipcode or (self.note == #self.pattern and self.current_note == dir_char and not self:getFlag("hassolved", false)) then
            Assets.playSound("noise")
            self.note = 0
            self.current_note = nil
            self.show_ui = false
            self.ui.exitlength = 0
            self.ui.drawpostarget = -0.1
            Game.world.timer:after(1, function()
                for i = 1, #self.pattern do
                    local dir_name = string.sub(self.pattern, i, i)
                    Game.world.timer:after(0.2 * i, function()
                        self:playNote(dir_name)
                    end)
                end
            end)
            Game.world.timer:after((0.2 * #self.pattern) + 2, function()
                Assets.playSound("sparkle_gem")
                self:setFlag("hassolved", true)
                self:exit(self.cutscene)
            end)
        end
    end
end

function PasswordPiano:draw()
    super.draw(self)
    self.siner = self.siner + 1
    local drawx = (self.sprite.width)
    local drawy = -36

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

        local tex = Assets.getTexture("ui/arrow_10x10")

        love.graphics.setColor(dir == nil and white_color or base_color)
        love.graphics.draw(Assets.getTexture("ui/circle_7x7"), drawx - 7, drawy - 7 + math.sin((self.siner + 210) / 9) * 2, 0, 2, 2)

        love.graphics.setColor(dir == "up" and white_color or base_color)
        love.graphics.draw(tex, drawx, drawy - 25 + math.sin((self.siner + 126) / 9) * 2, math.rad(180), 2, 2, 5, 5)

        love.graphics.setColor(dir == "down" and white_color or base_color)
        love.graphics.draw(tex, drawx, drawy + 25 + math.sin((self.siner + 42) / 9) * 2, math.rad(0), 2, 2, 5, 5)

        love.graphics.setColor(dir == "left" and white_color or base_color)
        love.graphics.draw(tex, drawx - 25, drawy + math.sin((self.siner + 168) / 9) * 2, math.rad(90), 2, 2, 5, 5)

        love.graphics.setColor(dir == "right" and white_color or base_color)
        love.graphics.draw(tex, drawx + 25, drawy + math.sin((self.siner + 84) / 9) * 2, math.rad(270), 2, 2, 5, 5)
    end

    if not DEBUG_RENDER then
        return
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(self.pattern, 0, -60)
    love.graphics.print(self.note.." : "..(self.current_note or "nil"), 0, -70)
    love.graphics.print(tostring(self:getFlag("hassolved", false)), 0, -80)
end

return PasswordPiano