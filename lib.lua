---@diagnostic disable: invisible
local lib = {}

Registry.registerGlobal("PianoPuzzleLib", lib)
PianoPuzzleLib = lib

function PianoPuzzleLib:onKeyPressed(key)
    if key == "h" then
    end
end

---
--- Returns a value eased between two numbers, determined by a percentage from 0 to 1.
---
---@param a number      # The start value of the range.
---@param b number      # The end value of the range.
---@param t number      # The percentage (from 0 to 1) that determines the point on the specified range.
---@param mode easetype # The ease type to use between the two values. (Refer to https://easings.net/)
---
function PianoPuzzleLib:ease(a, b, t, mode)
    if not Ease[mode] then
        error("\"" .. tostring(mode) .. "\" is not a valid easing method")
    end
    return Ease[mode](t, a, (b - a), 1)
end

-- Hi, this is super mega doodoo and I hate it.
-- I don't like directly using AI code but I've been looking at this for like an hour now and still don't get it.
-- If you want to remake this without the use of AI, PLEASEEE make a PR! I hate that this exists it's a stain on my otherwise fine library.
function PianoPuzzleLib:updateFloorHoles()
    local world = Game.world

    if not world.map.original_floor_colliders then
        world.map.original_floor_colliders = {}
        local i = 1
        while i <= #world.map.collision do
            local collider = world.map.collision[i]
            if collider.layer_name == "collision_floor_1" or collider.layer_name == "collision_floor_2" then
                table.insert(world.map.original_floor_colliders, collider)
                table.remove(world.map.collision, i)
            else
                i = i + 1
            end
        end
    end

    local i = 1
    while i <= #world.map.collision do
        if world.map.collision[i].is_bookshelf_cut then
            table.remove(world.map.collision, i)
        else
            i = i + 1
        end
    end

    local holes = {}
    for _, obj in ipairs(world.children) do
        if type(obj.stopMoving) == "function" and not obj.moving then
            table.insert(holes, {
                x = obj.x - 40,
                y = obj.y - 80,
                w = 80,
                h = 80
            })
        end
    end

    for _, orig_collider in ipairs(world.map.original_floor_colliders) do
        local current_rects = {
            {x = orig_collider.x, y = orig_collider.y, w = orig_collider.width, h = orig_collider.height}
        }

        for _, hole in ipairs(holes) do
            local next_rects = {}
            for _, rect in ipairs(current_rects) do
                if hole.x < rect.x + rect.w and hole.x + hole.w > rect.x and
                   hole.y < rect.y + rect.h and hole.y + hole.h > rect.y then

                    if hole.y > rect.y then
                        table.insert(next_rects, {x = rect.x, y = rect.y, w = rect.w, h = hole.y - rect.y})
                    end
                    if (hole.y + hole.h) < (rect.y + rect.h) then
                        table.insert(next_rects, {x = rect.x, y = hole.y + hole.h, w = rect.w, h = (rect.y + rect.h) - (hole.y + hole.h)})
                    end

                    if hole.x > rect.x then
                        local top_y = math.max(rect.y, hole.y)
                        local bot_y = math.min(rect.y + rect.h, hole.y + hole.h)
                        if bot_y > top_y then
                            table.insert(next_rects, {x = rect.x, y = top_y, w = hole.x - rect.x, h = bot_y - top_y})
                        end
                    end

                    if (hole.x + hole.w) < (rect.x + rect.w) then
                        local top_y = math.max(rect.y, hole.y)
                        local bot_y = math.min(rect.y + rect.h, hole.y + hole.h)
                        if bot_y > top_y then
                            table.insert(next_rects, {x = hole.x + hole.w, y = top_y, w = (rect.x + rect.w) - (hole.x + hole.w), h = bot_y - top_y})
                        end
                    end
                else
                    table.insert(next_rects, rect)
                end
            end
            current_rects = next_rects
        end

        if #current_rects > 0 then
            local new_group = ColliderGroup(orig_collider.parent or world)
            new_group.layer_name = orig_collider.layer_name
            new_group.is_bookshelf_cut = true

            new_group.collidable = orig_collider.collidable

            for _, r in ipairs(current_rects) do
                local new_hitbox = Hitbox(new_group.parent, r.x, r.y, r.w, r.h)
                new_hitbox.layer_name = orig_collider.layer_name
                new_hitbox.collidable = orig_collider.collidable

                new_group:addCollider(new_hitbox)
            end

            table.insert(world.map.collision, new_group)
        end
    end
end

return lib
