vector = require "libs.hump.vector"


function love.load()
    love.mouse.setVisible(false);

    blobs = {};

    for i = 1, 100 do
        table.insert(blobs, {x=math.random(1, 800),
                             y=math.random(1, 600),
                             r=math.random(2, 15),
                             spd=math.random(40, 90)})
    end
end


function love.update(dt)
    for i = 1, 100 do
        blobs[i].x = blobs[i].x - blobs[i].spd * dt;
        if blobs[i].x < -35 then
            blobs[i].x = math.random(830, 900)
            blobs[i].y = math.random(1, 600)
            blobs[i].r = math.random(2, 15)
            blobs[i].spd = math.random(40, 90)
        end
    end
end


function love.draw()
    mousex = love.mouse.getX();
    mousey = love.mouse.getY();
    love.graphics.setColor(255, 0, 0);
    love.graphics.circle("fill", mousex, mousey, 10);


    love.graphics.setColor(0, 255, 0);
    for i = 1, 100 do
        love.graphics.circle("fill", blobs[i].x, blobs[i].y, blobs[i].r)
    end
end


function love.keyreleased(key)
    if key == "escape" then
        love.event.quit();
    end
end