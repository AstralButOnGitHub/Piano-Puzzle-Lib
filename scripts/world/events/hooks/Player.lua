local Player, super = HookSystem.hookScript(Player)

function Player:init(chara, x, y)
    super.init(self, chara, x, y)
    self.ladderlayer = self.ladderlayer or 0
end

function Player:draw()
    super.draw(self)

    if DEBUG_RENDER then
        love.graphics.print("layer: "..self.ladderlayer, -20, -20)
        love.graphics.print("x: "..self.x.." y: "..self.y, -20, -10)
    end
end

return Player