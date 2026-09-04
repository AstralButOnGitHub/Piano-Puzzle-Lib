return {
    finish = function(cutscene, event)
        cutscene:wait(2)
        cutscene:setSpeaker("ralsei")
        cutscene:text("* Hey guys! It's me, Ralsei.")
        cutscene:text("* I drive a Mercedes Benz.")
    end
}