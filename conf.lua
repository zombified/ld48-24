function love.conf(t)
    t.title = "FLOW"
    t.author = "Joel Kleier"
    t.url = "http://ludumdare.com/"
    t.identity = "flow"
    t.version = "0.8.0"
    t.console = false
    t.release = false
    t.screen.width = 800
    t.screen.height = 600
    t.screen.fullscreen = false
    t.screen.vsync = true
    t.screen.fsaa = 0
    t.modules.joystick = true
    t.modules.audio = true
    t.modules.keyboard = true
    t.modules.event = true
    t.modules.image = true
    t.modules.graphics = true
    t.modules.timer = true
    t.modules.mouse = true
    t.modules.sound = true
    t.modules.physics = false
end