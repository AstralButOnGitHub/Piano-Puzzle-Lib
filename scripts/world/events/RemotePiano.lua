---@class MobilePiano : Event
---@overload fun(...) : MobilePiano
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
        local dist = math.max(MathUtils.round(MathUtils.dist(self.player.x, self.player.y, krx, kry) / 4), 1)
        dist = dist / 30
        self.world:setCameraAttached(false)
        self.player:walkTo(krx, kry, dist, "up");
        Game.world.can_open_menu = false
        self.show_ui = true
        Game.world.timer:after(dist, function()
            self.player:setFacing("up")
            self.player:resetSprite()
            self.player:setParent(self)
            self.player:setPosition(45, 94)
            self.current_bookshelf.controlled = true
            self.current_bookshelf.piano = self
        end)
    end
end

function RemotePiano:exit()
    self.show_ui = false
    self.current_bookshelf.controlled = false
    self.ui.drawpostarget = -0.1
    Game.world.timer:after(1, function ()
        self.player:setState("WALK")
        self.player:setFacing("down")
        Game.world.can_open_menu = true
        self.world:setCameraAttached(true)
        self.player:setParent(Game.world)
        self.player:setPosition(self.x, self.y + 55)
        self.player = nil
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

    if not self.current_bookshelf or not self.current_bookshelf.controlled then
        return
    end

    if Input.pressed("x", false) and self.ui.drawpos >= 1 and not self.current_bookshelf.moving then
        self:exit()
    end
    if self.type == "twotone" then
        if Input.pressed("c", false) and self.ui.drawpos >= 1 and not self.current_bookshelf.moving then
            self.twotone_id = self.twotone_id + 1
            if self.twotone_id > 2 then
                self.twotone_id = 1
            end
            self:setBookshelf(self.properties["target_"..self.twotone_id]["id"])
        end
    else
        if Input.pressed("c", false) then
            self:reset()
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

    if Input.down(dir) and Input.pressed("z", false) and self.current_bookshelf then
        if self.current_bookshelf:getMovinFoo(dir) then
            dir = nil
        end
    end
end

return RemotePiano