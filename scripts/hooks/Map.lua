local Map, super = HookSystem.hookScript(Map)

function Map:init(world, data)
    super.init(self, world, data)
    self.piano_collision = {}
end

function Map:loadLayer(layer, depth)
    super.loadLayer(self, layer, depth)

    if layer.type == "objectgroup" then
        if self:isLayerType(layer, "pianocollision") then
            TableUtils.merge(self.piano_collision, self:loadHitboxes(layer))
        end
    end
end

function Map:loadHitboxes(layer)
    local hitboxes = {}
    local ox, oy = layer.offsetx or 0, layer.offsety or 0
    for _, object in ipairs(layer.objects) do
        local hitbox = TiledUtils.colliderFromShape(self.world, object, object.x + ox, object.y + oy, object.properties)
        if hitbox then
            hitbox.layer_name = layer.name

            table.insert(hitboxes, hitbox)
            self.hitboxes_by_id[object.id] = hitbox

            self.hitboxes_by_name[object.name] = self.hitboxes_by_name[object.name] or {}
            table.insert(self.hitboxes_by_name[object.name], hitbox)
        end
    end
    return hitboxes
end

return Map