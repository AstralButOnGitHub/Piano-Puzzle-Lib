---@class PianoExit : Event
---@overload fun(...) : PianoExit
local PianoExit, super = Class(Event)

function PianoExit:init(data)
    super.init(self, data)
    self.properties = data.properties or {}

    self.targets = {}
    local i = 1
    while self.properties["target_" .. i] do
        table.insert(self.targets, self.properties["target_" .. i])
        i = i + 1
    end
    self.triggered = false
end

function PianoExit:onLoad()
    super.onLoad(self)
    self.target_x, self.target_y, _ = TiledUtils.parseMarkerProperty(self, self.targets[1], "target")
end

function PianoExit:update()
    if self.triggered then return end

    for _, object in ipairs(Game.world.map:getEvents()) do
        if object.id == "MovingPiano" and self:meetsObject(object) and object.controlled == true then
            self.triggered = true
            object.jumpedoff = true

            local player = object.player
            local characters = object.characters

            local jumptime = 16 / 30
            local jump_height = 20

            object.controlled = false
            object.show_ui = false
            object.ui.exitlength = 0
            object.ui.drawpostarget = -0.1

            player:setParent(Game.world)
            player:setPosition(object.x + 40, object.y + 40)

            local followers = {}

            for i, chara in ipairs(characters) do
                local target_x, target_y, _ = TiledUtils.parseMarkerProperty(self, self.targets[i + 1], "target")
                local follower = chara:convertToFollower()
                chara:remove()
                follower:setPosition(object.x + 40, object.y + 40)
                Game.world:detachFollowers()

                follower:setAnimation("jump_ball")
                follower:jumpTo(target_x, target_y, jump_height, jumptime)
                table.insert(followers, {follower = follower, x = target_x, y = target_y})
            end

            player:setAnimation("jump_ball")
            player:jumpTo(self.target_x, self.target_y, jump_height, jumptime)
            self.world.camera:panTo(self.target_x, self.target_y - 40, jumptime)

            Game.world.timer:after(jumptime, function()
                player:setState("WALK")
                Game.world.can_open_menu = true
                Game.world:setCameraAttached(true)
                player:resetSprite()

                for _, entry in ipairs(followers) do
                    entry.follower:setPosition(entry.x, entry.y)
                    entry.follower:interpolateHistory()
                end

                Game.world:attachFollowersImmediate()

                object.player = nil
                self.triggered = false
            end)
        end
    end
end

return PianoExit