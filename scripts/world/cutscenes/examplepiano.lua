return {
    finish = function(cutscene, event)
        Game.world:getEvent(253):unlock()
        cutscene:setSpeaker("ralsei")
        cutscene:text("* Hey guys! It's me, Ralsei.")
        cutscene:text("* I drive a Mercedes Benz.")
    end
}