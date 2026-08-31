---@class BreakableBookshelf : Event
---@overload fun(...) : BreakableBookshelf
local BreakableBookshelf, super = Class(Event)

function BreakableBookshelf:init(data)
    super.init(self, data)
    self.properties = data.properties or {}

    self.texture = self.properties["texture"] or "world/spr_dw_church_shelfpuz_2x2"

    self:setHitbox(0, 80, 80, 80)
    self:setOrigin(0.5, 0.5)
    self.solid = true
    self:setSprite(self.texture)
    self.exploded = false
end

function BreakableBookshelf:holyFuckingShitExplode(bookshelf)
    self.exploded = true
    self.solid = false
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

function BreakableBookshelf:update()
    super.update(self)
    if self.exploded then
        return
    end
    for _, bookshelf in ipairs(Game.world.map:getEvents("MovingBookshelf")) do
        if self:meetsObject(bookshelf) then
            self:holyFuckingShitExplode(bookshelf)
        end
    end
end

function BreakableBookshelf:draw()
    super.draw(self)
end

return BreakableBookshelf