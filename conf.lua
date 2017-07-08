function love.conf(t)
    t.identity = "MP"
    t.version = "0.10.2"
    t.console = false

    t.window.title = "MP"
    t.window.icon = nil
    t.window.width = 360
    t.window.height = 600
    t.window.borderless = false
    t.window.resizable = false
    t.window.minwidth = 1
    t.window.minheight = 1
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop" -- Choose between "desktop" fullscreen or "exclusive" fullscreen mode (string)
    t.window.vsync = false
    t.window.msaa = 0
    t.window.display = 1
    t.window.highdpi = false
    t.window.x = nil
    t.window.y = nil
end
