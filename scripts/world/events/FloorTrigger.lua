---@class FloorTrigger : Event
---@overload fun(...) : FloorTrigger
local FloorTrigger, super = Class(Event)

function FloorTrigger:init(data)
    super.init(self, data)
    self.amount = data.properties and data.properties["amount"] or 1
    self.entry_y = 0
end

function FloorTrigger:onLoad()
    -- it took me almost an hour to figure this out.
    -- AGHHHHHHHHHHHHHHHHHHHHHH
    Game.world.timer:after(0, function()
        if Game.world.player then
            self.entry_y = Game.world.player.y
            self:updateFloorLayers(Game.world.player, false)
        end
    end)
end

function FloorTrigger:onEnter(player)
    super.onEnter(self, player)
    self.entry_y = player.y
    self:updateFloorLayers(Game.world.player, true)
end

function FloorTrigger:onExit(player)
    super.onExit(self, player)
    local mid = self.y + (self.height / 2)

    if self.entry_y > mid and player.y <= self.y then
        player.ladderlayer = math.min(1, (player.ladderlayer or 0) + self.amount)
    elseif self.entry_y <= mid and player.y >= self.y + self.height then
        player.ladderlayer = math.max(0, (player.ladderlayer or 0) - self.amount)
    end

    self:updateFloorLayers(player, false)
end

function FloorTrigger:updateFloorLayers(player, onlylayers)
    local ladderlayer = player and player.ladderlayer or 0
    if onlylayers then
        ladderlayer = 1
    end

    if not onlylayers then
        for _, hitbox in ipairs(Game.world.map.collision) do
            if hitbox.layer_name == "collision_floor_1" then
                hitbox.collidable = (ladderlayer ~= 1)

                if hitbox.colliders then
                    for _, child in ipairs(hitbox.colliders) do
                        child.collidable = (ladderlayer ~= 1)
                    end
                end

            elseif hitbox.layer_name == "collision_floor_2" then
                hitbox.collidable = (ladderlayer == 1)

                if hitbox.colliders then
                    for _, child in ipairs(hitbox.colliders) do
                        child.collidable = (ladderlayer == 1)
                    end
                end
            end
        end

        if Game.world.map.original_floor_colliders then
            for _, hitbox in ipairs(Game.world.map.original_floor_colliders) do
                if hitbox.layer_name == "collision_floor_1" then
                    hitbox.collidable = (ladderlayer ~= 1)
                elseif hitbox.layer_name == "collision_floor_2" then
                    hitbox.collidable = (ladderlayer == 1)
                end
            end
        end
    end

    for _, object in ipairs(Game.stage:getObjects(Object)) do
        if object.floor_layer_data == nil then
            object.floor_layer_data = {
                ["solid"] = object.solid,
                ["collidable"] = object.collidable,
                ["active"] = object.active
            }
        end
        local layer_name = object.layer_name or ""

        if object.id == "MovingBookshelf" then
            object.solid = ladderlayer == 0
        end

        if layer_name:find("floor_1") or layer_name:find("floor_2") or (object.properties and object.properties["do_floors"]) then
            object.layer = ladderlayer == 1 and player.layer - 0.1 or player.layer
        end

        if not object:includes(Sprite) and not object:includes(Collider) then
            if layer_name:find("floor_1") or layer_name:find("floor_2") then
                if player then
                    if ladderlayer == 0 then
                        object.layer = player.layer + 100
                        object.solid = false
                        object.collidable = false
                        object.active = false
                    else
                        object.layer = player.layer
                        object.solid = object.floor_layer_data["solid"]
                        object.collidable = object.floor_layer_data["collidable"]
                        object.active = object.floor_layer_data["active"]
                    end
                end
            end
        end
    end
end

return FloorTrigger