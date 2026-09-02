---@class BreakableBookshelf : Event
---@overload fun(...) : BreakableBookshelf
local BreakableBookshelf, super = Class(Event)

function BreakableBookshelf:init(data)
    super.init(self, data)
    self.properties = data.properties or {}

    self.special = self.properties["special"] or ""
    self.slow_down = self.properties["slow_down"] or true

    if self.special == "music_gate" then
        self.texture = self.properties["texture"] or "world/events/music_gate_breakable"
        self.x = self.x - 5 - 40
        self.y = self.y - 40 - 160
        self:setHitbox(0, 180, 90, 20)
        self:setOrigin(0, 0)
    else
        self.texture = self.properties["texture"] or "world/spr_dw_church_shelfpuz_2x2"
        self:setHitbox(0, 80, 80, 80)
        self:setOrigin(0.5, 0.5)
    end

    self.solid = true
    self:setSprite(self.texture)
    self.exploded = false
end

function BreakableBookshelf:holyFuckingShitExplode(bookshelf)
    self.exploded = true
    self.solid = false
    if self.slow_down and bookshelf.can_slow_down then
        bookshelf:setSpeed(bookshelf.velx * 0.7, bookshelf.vely * 0.7)
    end

    if self.special == "music_gate" then
        local debris_x = {-6, -3, 4, 11, 20, 43, 31, 42, 48, 58, 69}
        local debris_y = {52, 40, 34, 36, 8, 25, 71, 48, 59, 60, 36}
        local debris_hspeeds = {-2, -1.5, -1.2, -1.1, -0.5, 1.2, 0.2, 0.6, 1.35, 1.45, 2}
        local debris_vspeeds = {-2, -2.5, -2.8, -2.9, -3.5, -2.7, -1.5, -2.2, -2, -1.9, -2.1}
        self.visible = false
        for i = 1, 11, 1 do
            local debris = Sprite("effects/music_gate_debris_"..i, self.x + (debris_x[i] * 0.5), self.y + (debris_y[i] * 2))
            debris.scale_x = debris.scale_x * 2
            debris.scale_y = debris.scale_y * 2

            debris.layer = 49600
            debris:setSpeed(debris_hspeeds[i] * 3, debris_vspeeds[i] * 3)
            debris.physics.gravity = 1
            Game.world:addChild(debris)
            debris:fadeOutAndRemove(1)
        end
    else
        self.x = self.x + 40
        local debris = Sprite("effects/bookshelf_debris_"..math.random(1, 5), self.x - 80, self.y)
        debris.layer = self.layer - 0.1
        Game.world:addChild(debris)
        -- Assets.playSound("bomb", 1, 1)
        Assets.playSound("impact", 1, 1)

        local explosion = Sprite("effects/explosion_round", -(25 / 2), 60)
        self.layer = 49600
        explosion.scale_x = explosion.scale_x * 2
        explosion.scale_y = explosion.scale_y * 2
        explosion:play(0.1, false, function(sprite)
            sprite:remove()
        end)
        self:addChild(explosion)

        local chunkstuff = {
            {0, 0},
            {1, 0},
            {0, 1},
            {1, 1}
        }
        local chunkvelstuff = {
            {-1, -1},
            {1, -1},
            {-1, 1},
            {1, 1}
        }
        for i = 1, 4 do
            local chunk = Sprite("effects/bookshelf_chunk_"..i, chunkstuff[i][1] * 70, chunkstuff[i][2] * 70)
            self.layer = 49600
            chunk.scale_x = chunk.scale_x * 2
            chunk.scale_y = chunk.scale_y * 2
            chunk.x = chunk.x - 15
            chunk.y = chunk.y - 5
            self:addChild(chunk)
            local speed = 10
            chunk:setSpeed(chunkvelstuff[i][1] * speed, chunkvelstuff[i][2] * speed)
            chunk:fadeOutAndRemove(0.25)
        end

        self:setSprite("effects/bookshelf_scatter_"..math.random(1, 2))
        self.sprite:play(0.1, false, function(sprite)
            sprite:remove()
        end)
        self.sprite.scale_x = self.sprite.scale_x / 2
        self.sprite.scale_y = self.sprite.scale_y / 2
    end
end

function BreakableBookshelf:update()
    super.update(self)
    if self.exploded then
        return
    end
    for _, bookshelf in ipairs(Game.world.map:getEvents()) do
        if bookshelf:includes(MovingObject) and self:meetsObject(bookshelf) then
            self:holyFuckingShitExplode(bookshelf)
        end
    end
end

function BreakableBookshelf:draw()
    super.draw(self)
end

return BreakableBookshelf