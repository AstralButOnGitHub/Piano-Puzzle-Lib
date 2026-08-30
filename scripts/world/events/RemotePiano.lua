---@class RemotePiano : Event
---@overload fun(...) : RemotePiano
local RemotePiano, super = Class(Event)

function RemotePiano:init(data)
    super.init(self, data)
    self.properties = data.properties or {}

    self.type = self.properties["type"] or "blue"
    self:setSprite("world/events/remotepiano_"..self.type)
    self:setHitbox(6, 22*2, 40*2, 12*2)
    self.solid = true
    self:setOrigin(0.5, 0.5)

    self.camera_posx = self.properties["camera_posx"] or nil
    self.camera_posy = self.properties["camera_posy"] or nil

    self.player = nil
    self.current_bookshelf = nil
    self.twotone_id = 1
    self.ui = nil
    self.exiting = false
end

function RemotePiano:onLoad()
    if self.type == "twotone" then
        self:setBookshelf(self.properties["target_"..self.twotone_id]["id"], true)
    else
        self:setBookshelf(self.properties["target"]["id"], true)
    end
end

function RemotePiano:setBookshelf(event_id, dont_select)
    local dont_select = dont_select or false
    if self.current_bookshelf then
        self.current_bookshelf.controlled = false
    end
    self.current_bookshelf = Game.world.map:getEvent(event_id)
    self.current_bookshelf.controlled = not dont_select
    Kristal.Console:log(event_id)
end

function RemotePiano:onInteract(player, dir)
    if dir == "up" and self.current_bookshelf then
        self.player = player
        self.player:setState("PIANO")
        local krx = self.x
        local kry = self.y + 53
        if self.type == "twotone" then
            if self.twotone_id ~= 1 then
                krx = self.x - 10
                kry = self.y + 53
            else
                krx = self.x + 10
                kry = self.y + 53
            end
        end
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
            self.current_bookshelf.controlled = true
            self.current_bookshelf.piano = self
        end)
    end
end

function RemotePiano:exit()
    if self.exiting or not self.player then
        return
    end

    self.exiting = true

    local player = self.player

    self.show_ui = false
    self.ui.exitlength = 0
    self.current_bookshelf.controlled = false
    self.ui.drawpostarget = -0.1

    Game.world.timer:after(1, function()
        if not player then
            self.exiting = false
            return
        end

        player:setState("WALK")
        player:setFacing("down")
        player:setParent(Game.world)
        player:setPosition(self.x, self.y + 55)

        Game.world.can_open_menu = true
        self.world:setCameraAttached(true)

        self.player = nil
        self.exiting = false
    end)
end

function RemotePiano:reset()
    if self.current_bookshelf and not self.current_bookshelf.moving and not self.current_bookshelf.resetting then
        self.current_bookshelf.reset_timer = 0
        self.current_bookshelf.resetting = true
    end
end

function RemotePiano:update()
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
        if self.current_bookshelf.moving and dir ~= nil then
            table.insert(self.current_bookshelf.storedinputs, dir)
            table.insert(self.current_bookshelf.storedinputdementia, 0)
            return
        end
        if self.current_bookshelf:getMovinFoo(dir) then
            dir = nil
        end
    end
end

function RemotePiano:draw()
    super.draw(self)
    if not DEBUG_RENDER then
        return
    end

    if self.type == "twotone" then
        love.graphics.print(self.twotone_id, -20, 30)
    end
end

return RemotePiano